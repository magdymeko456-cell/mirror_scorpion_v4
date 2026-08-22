export type ClassicVoiceProfile = {
  id: string;
  name: string;
  description: string;
  gender: "male" | "female";
  pitch: number;
  rate: number;
};

export const classicVoices: ClassicVoiceProfile[] = [
  { id: "scorpion_royal", name: "صوت العقرب الملكي (Royal Scorpion)", description: "قراءة فخمة وعميقة تناسب الحوارات الرسمية والقصص التاريخية، مع نبرة رصينة ومؤثرة.", gender: "male", pitch: 0.8, rate: 0.95 },
  { id: "desert_breeze", name: "نسيم الصحراء (Desert Breeze)", description: "صوت هادئ وواضح يتميز بنقاء عالٍ ومرونة في نطق اللغات المختلفة بطلاقة.", gender: "female", pitch: 1.1, rate: 1.0 },
  { id: "scorpion_commander", name: "قائد العقرب (Commander)", description: "نبرة حازمة وحادة تعكس القوة واليقظة، مثالية للتعليمات والنصوص السريعة.", gender: "male", pitch: 0.9, rate: 1.05 },
  { id: "oasis_harmony", name: "واحة الانسجام (Oasis Harmony)", description: "صوت دافئ ومريح يعطي شعوراً بالألفة والطمأنينة أثناء قراءة القصص والأسباب.", gender: "female", pitch: 1.0, rate: 0.98 },
  { id: "scorpion_echo", name: "صدى الصحراء (Desert Echo)", description: "صوت سينمائي عميق مع صدى خفيف يضفي هيبة على الحوارات المترجمة.", gender: "male", pitch: 0.75, rate: 0.9 },
];

export type UserVoiceCloneState = {
  isCloned: boolean;
  sampleUri?: string;
  clonedAt?: number;
};
