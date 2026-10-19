import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface RequestPayload {
  action:
    | "dictionary"
    | "conversation"
    | "conversation_continuation"
    | "lesson_topics"
    | "lesson_detail"
    | "hsk_exam"
    | "hsk_exam_analysis"
    | "hsk_vocabulary"
    | "translate"
    | "ocr";
  payload: Record<string, any>;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY") ?? "";

    if (!geminiApiKey) {
      return new Response(
        JSON.stringify({
          error: "ai_temporarily_unavailable",
          message: "Gemini API key is not configured on the server.",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Authenticate caller
    const authHeader = req.headers.get("Authorization");
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader ?? "" } },
    });

    let userId: string | null = null;

    if (authHeader) {
      const {
        data: { user },
      } = await supabaseClient.auth.getUser();
      if (user) {
        userId = user.id;
      }
    }

    const body: RequestPayload = await req.json();
    const { action, payload } = body;

    if (!action || !payload) {
      return new Response(
        JSON.stringify({
          error: "invalid_input",
          message: "Request must include action and payload.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check & increment daily quota if user is authenticated
    if (userId && supabaseServiceKey) {
      const adminClient = createClient(supabaseUrl, supabaseServiceKey);
      const { error: quotaError } = await adminClient.rpc(
        "check_and_increment_ai_quota",
        {
          p_user_id: userId,
          p_tokens: 100,
        }
      );

      if (quotaError) {
        if (quotaError.message.includes("quota_exceeded")) {
          return new Response(
            JSON.stringify({
              error: "quota_exceeded",
              message:
                "Bạn đã đạt giới hạn lượt sử dụng AI trong ngày. Vui lòng thử lại vào ngày mai.",
            }),
            {
              status: 429,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }
      }
    }

    // Build Gemini prompt and schema based on action
    let prompt = "";
    let schema: Record<string, any> = {};

    switch (action) {
      case "dictionary": {
        const word = (payload.word || "").toString().trim();
        if (!word) {
          throw new Error("Từ tra cứu không được để trống.");
        }
        prompt = `Provide a detailed dictionary entry for the word "${word}". The word can be in either Vietnamese or Chinese. Include Hanzi, Pinyin, Vietnamese meaning, 2-3 examples (with pinyin and Vietnamese translation), and grammar notes. Treat it as a dictionary lookup, not a full-sentence translation.`;
        schema = {
          type: "OBJECT",
          properties: {
            source_lang: { type: "STRING" },
            target_lang: { type: "STRING" },
            hanzi: { type: "STRING" },
            pinyin: { type: "STRING" },
            vi_meaning: { type: "STRING" },
            examples: {
              type: "ARRAY",
              items: {
                type: "OBJECT",
                properties: {
                  zh: { type: "STRING" },
                  pinyin: { type: "STRING" },
                  vi: { type: "STRING" },
                },
                required: ["zh", "pinyin", "vi"],
              },
            },
            grammar_notes: {
              type: "ARRAY",
              items: { type: "STRING" },
            },
          },
          required: [
            "source_lang",
            "target_lang",
            "hanzi",
            "pinyin",
            "vi_meaning",
            "examples",
            "grammar_notes",
          ],
        };
        break;
      }

      case "conversation": {
        const level = payload.level || 1;
        const topic = payload.topic ? `about the topic "${payload.topic}"` : "on a common daily life subject";
        prompt = `Generate a short conversation in Chinese ${topic} suitable for HSK level ${level}. 6-8 turns between two speakers (A and B). Consistent topic, turn number, Chinese text (zh), Pinyin, and Vietnamese translation (vi).`;
        schema = {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              topic: { type: "STRING" },
              turn: { type: "INTEGER" },
              zh: { type: "STRING" },
              pinyin: { type: "STRING" },
              vi: { type: "STRING" },
            },
            required: ["topic", "turn", "zh", "pinyin", "vi"],
          },
        };
        break;
      }

      case "conversation_continuation": {
        const level = payload.level || 1;
        const existingLines = payload.existingLines || [];
        const lastLine = existingLines[existingLines.length - 1] || {};
        const topic = lastLine.topic || "Chủ đề hội thoại";
        const turn = lastLine.turn || 0;
        const conversationHistory = existingLines
          .map((line: any) => `${(line.turn % 2 === 1 ? "A" : "B")}: ${line.zh}`)
          .join("\n");

        prompt = `Existing conversation for HSK level ${level} on "${topic}":\n${conversationHistory}\nGenerate the next 2 to 4 turns logically. Provide topic, turn (starting from ${turn + 1}), zh, pinyin, vi.`;
        schema = {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              topic: { type: "STRING" },
              turn: { type: "INTEGER" },
              zh: { type: "STRING" },
              pinyin: { type: "STRING" },
              vi: { type: "STRING" },
            },
            required: ["topic", "turn", "zh", "pinyin", "vi"],
          },
        };
        break;
      }

      case "lesson_topics": {
        const level = payload.level || 1;
        prompt = `Generate a list of 10-12 diverse and practical lesson topics for a student learning HSK level ${level}. Title and one-sentence description in Vietnamese.`;
        schema = {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              title: { type: "STRING" },
              description: { type: "STRING" },
            },
            required: ["title", "description"],
          },
        };
        break;
      }

      case "lesson_detail": {
        const level = payload.level || 1;
        const topic = payload.topic || "Bài học";
        prompt = `Create a detailed Chinese lesson for HSK level ${level} on topic: "${topic}". Include dialogue (4-6 turns), key_vocabulary (5-7 words), grammar_points (2-3 points with explanation and examples).`;
        schema = {
          type: "OBJECT",
          properties: {
            level: { type: "NUMBER" },
            title: { type: "STRING" },
            dialogue: {
              type: "ARRAY",
              items: {
                type: "OBJECT",
                properties: {
                  speaker: { type: "STRING" },
                  zh: { type: "STRING" },
                  pinyin: { type: "STRING" },
                  vi: { type: "STRING" },
                },
                required: ["speaker", "zh", "pinyin", "vi"],
              },
            },
            key_vocabulary: {
              type: "ARRAY",
              items: {
                type: "OBJECT",
                properties: {
                  hanzi: { type: "STRING" },
                  pinyin: { type: "STRING" },
                  meaning_vi: { type: "STRING" },
                },
                required: ["hanzi", "pinyin", "meaning_vi"],
              },
            },
            grammar_points: {
              type: "ARRAY",
              items: {
                type: "OBJECT",
                properties: {
                  point: { type: "STRING" },
                  explanation_vi: { type: "STRING" },
                  examples: {
                    type: "ARRAY",
                    items: {
                      type: "OBJECT",
                      properties: {
                        zh: { type: "STRING" },
                        pinyin: { type: "STRING" },
                        vi: { type: "STRING" },
                      },
                      required: ["zh", "pinyin", "vi"],
                    },
                  },
                },
                required: ["point", "explanation_vi", "examples"],
              },
            },
          },
          required: ["level", "title", "dialogue", "key_vocabulary", "grammar_points"],
        };
        break;
      }

      case "hsk_exam": {
        const level = payload.level || 1;
        const total = 20;
        prompt = `Generate a mock HSK ${level} exam with ${total} questions. Return: section, question_text, audio_script, options (4 strings), correct_answer, explanation (Vietnamese).`;
        schema = {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              section: { type: "STRING" },
              question_text: { type: "STRING" },
              audio_script: { type: "STRING" },
              options: { type: "ARRAY", items: { type: "STRING" } },
              correct_answer: { type: "STRING" },
              explanation: { type: "STRING" },
            },
            required: ["section", "question_text", "options", "correct_answer", "explanation"],
          },
        };
        break;
      }

      case "hsk_exam_analysis": {
        const level = payload.level || 1;
        const score = payload.score || 0;
        const total = payload.totalQuestions || 20;
        const incorrectAnswers = (payload.questionsAndAnswers || []).filter(
          (q: any) => q.user_answer !== q.correct_answer
        );

        prompt = `Act as an expert HSK teacher. Student completed HSK ${level} mock exam. Score: ${score}/${total}. Incorrect answers: ${JSON.stringify(
          incorrectAnswers
        )}. Return overall_assessment, strengths (2-3), weaknesses (2-3), study_suggestions (2-3) in Vietnamese.`;
        schema = {
          type: "OBJECT",
          properties: {
            overall_assessment: { type: "STRING" },
            strengths: { type: "ARRAY", items: { type: "STRING" } },
            weaknesses: { type: "ARRAY", items: { type: "STRING" } },
            study_suggestions: { type: "ARRAY", items: { type: "STRING" } },
          },
          required: [
            "overall_assessment",
            "strengths",
            "weaknesses",
            "study_suggestions",
          ],
        };
        break;
      }

      case "hsk_vocabulary": {
        const level = payload.level || 1;
        const count = Math.min(payload.count || 20, 50);
        prompt = `Generate ${count} HSK ${level} vocabulary words with level, hanzi, pinyin, meaning_vi, pos, and example_zh/example_pinyin/example_vi.`;
        schema = {
          type: "ARRAY",
          items: {
            type: "OBJECT",
            properties: {
              level: { type: "NUMBER" },
              hanzi: { type: "STRING" },
              pinyin: { type: "STRING" },
              meaning_vi: { type: "STRING" },
              pos: { type: "STRING" },
              example_zh: { type: "STRING" },
              example_pinyin: { type: "STRING" },
              example_vi: { type: "STRING" },
            },
            required: [
              "level",
              "hanzi",
              "pinyin",
              "meaning_vi",
              "pos",
              "example_zh",
              "example_pinyin",
              "example_vi",
            ],
          },
        };
        break;
      }

      default:
        return new Response(
          JSON.stringify({
            error: "invalid_action",
            message: `Unsupported action "${action}".`,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
    }

    // Call Gemini API securely from Edge Server
    const geminiEndpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;

    const geminiRequest = {
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: schema,
      },
    };

    const geminiResponse = await fetch(geminiEndpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiRequest),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error(`Gemini API error: ${geminiResponse.status} ${errText}`);
      return new Response(
        JSON.stringify({
          error: "ai_temporarily_unavailable",
          message:
            "Không thể kết nối với dịch vụ AI vào lúc này. Vui lòng thử lại sau.",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const geminiData = await geminiResponse.json();
    const candidate = geminiData.candidates?.[0];
    const rawText = candidate?.content?.parts?.[0]?.text;

    if (!rawText) {
      return new Response(
        JSON.stringify({
          error: "empty_response",
          message: "Dịch vụ AI phản hồi dữ liệu trống.",
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const parsedResult = JSON.parse(rawText.trim());

    return new Response(
      JSON.stringify({
        success: true,
        action,
        data: parsedResult,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    console.error("Unhandled error in gemini-ai-gateway:", err);
    return new Response(
      JSON.stringify({
        error: "internal_error",
        message: err.message || "Lỗi nội bộ hệ thống AI gateway.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
