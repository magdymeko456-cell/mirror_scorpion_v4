export type StoryVideoScene = {
  sceneNumber: number;
  title: string;
  narrativeText: string;
  visualPrompt: string;
  durationSeconds: number;
};

export type StoryVideoProject = {
  storyId: string;
  title: string;
  source: string;
  fullText: string;
  scenes: StoryVideoScene[];
  createdAt: number;
};

export function buildStoryVideoScript(storyId: string, title: string, source: string, fullText: string): StoryVideoProject {
  const cleanText = fullText.trim();
  // Split into detailed paragraphs to generate a rich multi-scene video script without abbreviation
  const paragraphs = cleanText.split(/\n+/).filter((p) => p.trim().length > 0);
  const scenes: StoryVideoScene[] = paragraphs.map((para, index) => ({
    sceneNumber: index + 1,
    title: `المشهد ${index + 1}: ${title}`,
    narrativeText: para,
    visualPrompt: `Cinematic dramatic lighting, 8k resolution, photorealistic historical documentary style depicting: ${para.slice(0, 120)}`,
    durationSeconds: Math.min(15, Math.max(6, Math.round(para.length / 18))),
  }));

  if (scenes.length === 0) {
    scenes.push({
      sceneNumber: 1,
      title: `المشهد الأول: ${title}`,
      narrativeText: cleanText,
      visualPrompt: `Cinematic 8k historical illustration of ${title}`,
      durationSeconds: 10,
    });
  }

  return {
    storyId,
    title,
    source,
    fullText: cleanText,
    scenes,
    createdAt: Date.now(),
  };
}
