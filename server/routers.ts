import { COOKIE_NAME } from "../shared/const.js";
import { getSessionCookieOptions } from "./_core/cookies";
import { systemRouter } from "./_core/systemRouter";
import { publicProcedure, router } from "./_core/trpc";
import { z } from "zod";
import { supportedTranslationLanguages, translateText, uploadAndTranslateAudio } from "./translation";
import { generateInspirationMessage, generateStoryVideoScript, inspirationCatalog } from "./inspiration";
import { buildOfflineLanguagePack } from "./offline-packs";
import { extractAndTranslateDocument } from "./documents";
import { getProVerificationStatus, verifyProActivationPatch } from "./pro-activation";

const translationLanguage = z.enum(supportedTranslationLanguages);

export const appRouter = router({
  // if you need to use socket.io, read and register route in server/_core/index.ts, all api should start with '/api/' so that the gateway can route correctly
  system: systemRouter,
  auth: router({
    me: publicProcedure.query((opts) => opts.ctx.user),
    logout: publicProcedure.mutation(({ ctx }) => {
      const cookieOptions = getSessionCookieOptions(ctx.req);
      ctx.res.clearCookie(COOKIE_NAME, { ...cookieOptions, maxAge: -1 });
      return {
        success: true,
      } as const;
    }),
  }),

  inspiration: router({
    catalog: publicProcedure.query(() => inspirationCatalog),
    message: publicProcedure
      .input(z.object({
        mood: z.string().trim().max(240).optional(),
        focus: z.string().trim().max(240).optional(),
        language: z.enum(["ar", "en"]).default("ar"),
      }))
      .mutation(({ input }) => generateInspirationMessage(input)),
    videoScript: publicProcedure
      .input(z.object({
        title: z.string().trim().min(1).max(240),
        category: z.string().trim().min(1).max(120),
        fullText: z.string().trim().min(80).max(24_000),
        language: z.enum(["ar", "en"]).default("ar"),
      }))
      .mutation(({ input }) => generateStoryVideoScript(input)),
  }),

  pro: router({
    status: publicProcedure.query(() => getProVerificationStatus()),
    activate: publicProcedure
      .input(z.object({
        deviceId: z.string().trim().min(12).max(120),
        patch: z.string().trim().min(12).max(8_192),
      }))
      .mutation(({ input }) => verifyProActivationPatch(input)),
  }),

  translation: router({
    text: publicProcedure
      .input(z.object({
        text: z.string().trim().min(1).max(5000),
        targetLanguage: translationLanguage,
        sourceLanguage: z.union([translationLanguage, z.literal("auto")]).default("auto"),
      }))
      .mutation(({ input }) => translateText(input)),

    pack: publicProcedure
      .input(z.object({ language: translationLanguage }))
      .mutation(({ input }) => buildOfflineLanguagePack(input.language)),

    ocr: publicProcedure
      .input(z.object({
        base64: z.string().min(32).max(18_000_000),
        fileName: z.string().min(1).max(180),
        mimeType: z.string().min(1).max(100),
        targetLanguage: translationLanguage,
      }))
      .mutation(({ input }) => extractAndTranslateDocument(input)),

    audio: publicProcedure
      .input(z.object({
        base64: z.string().min(16).max(24_000_000),
        fileName: z.string().min(1).max(180),
        mimeType: z.string().regex(/^audio\//),
        targetLanguage: translationLanguage,
        sourceLanguage: z.union([translationLanguage, z.literal("auto")]).default("auto"),
      }))
      .mutation(({ input }) => uploadAndTranslateAudio(input)),
  }),

  // TODO: add feature routers here, e.g.
  // todo: router({
  //   list: protectedProcedure.query(({ ctx }) =>
  //     db.getUserTodos(ctx.user.id)
  //   ),
  // }),
});

export type AppRouter = typeof appRouter;
