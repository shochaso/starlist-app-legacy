import { YoutubeVideoBasic, YoutubeClient } from './youtubeClient';
import { cache, CACHE_TTL, cacheKeys } from './cache';

export class YoutubeCachedClient extends YoutubeClient {
  private client: YoutubeClient;

  constructor(apiKey?: string) {
    super(apiKey);
    this.client = new YoutubeClient(apiKey);
  }

  async fetchVideoById(videoId: string): Promise<YoutubeVideoBasic | null> {
    const cacheKey = cacheKeys.youtubeVideo(videoId);

    // Try cache first
    const cached = await cache.get<YoutubeVideoBasic>(cacheKey);
    if (cached) {
      return cached;
    }

    // Fetch from API
    try {
      const result = await this.client.fetchVideoById(videoId);
      if (result) {
        await cache.set(cacheKey, result, CACHE_TTL.YOUTUBE_VIDEO);
      }
      return result;
    } catch (error) {
      // Log safely without exposing secrets
      console.error(`YouTube API error for videoId ${videoId}:`, error instanceof Error ? error.message : 'Unknown error');
      return null;
    }
  }

  async searchVideos(query: string, opts?: { maxResults?: number }): Promise<YoutubeVideoBasic[]> {
    // For search, we don't cache as it's dynamic
    return this.client.searchVideos(query, opts);
  }
}

export function createYoutubeCachedClient(apiKey?: string): YoutubeCachedClient {
  return new YoutubeCachedClient(apiKey);
}
