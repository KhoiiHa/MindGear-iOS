/* eslint-disable no-console */
const fs = require("fs");
const path = require("path");

const API_KEY = process.env.YOUTUBE_API_KEY;
if (!API_KEY || API_KEY.trim() === "" || API_KEY === "REPLACE_ME") {
  console.error("❌ YOUTUBE_API_KEY fehlt oder ist ungültig.");
  process.exit(1);
}

const ROOT = process.cwd();
const DATA_DIR = path.join(ROOT, "data");
const SOURCES = require(path.join(ROOT, "tools/youtube/sources.json"));

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function yt(endpoint, params) {
  const url = new URL(`https://www.googleapis.com/youtube/v3/${endpoint}`);
  Object.entries({ key: API_KEY, ...params }).forEach(([k, v]) => {
    if (v !== undefined && v !== null) url.searchParams.set(k, String(v));
  });
  const res = await fetch(url);
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`YouTube API error ${res.status}: ${txt}`);
  }
  return res.json();
}

async function fetchPlaylistMeta(playlistId) {
  const json = await yt("playlists", { part: "snippet", id: playlistId });
  const item = json.items?.[0];
  if (!item) return null;
  const s = item.snippet;
  return {
    id: item.id,
    title: s.title,
    description: s.description,
    channelTitle: s.channelTitle,
    thumbnails: {
      default: s.thumbnails?.default?.url ?? null,
      medium: s.thumbnails?.medium?.url ?? null,
      high: s.thumbnails?.high?.url ?? null
    }
  };
}

async function fetchAllPlaylistItems(playlistId, max = 500) {
  let pageToken = undefined;
  const items = [];
  do {
    const json = await yt("playlistItems", {
      part: "snippet,contentDetails",
      playlistId,
      maxResults: 50,
      pageToken
    });
    for (const it of json.items ?? []) {
      const sn = it.snippet ?? {};
      const cd = it.contentDetails ?? {};
      items.push({
        id: cd.videoId ?? sn.resourceId?.videoId ?? null,
        title: sn.title ?? "",
        description: sn.description ?? "",
        publishedAt: sn.publishedAt ?? cd.videoPublishedAt ?? null,
        position: sn.position ?? null,
        channelTitle: sn.channelTitle ?? null,
        thumbnails: {
          default: sn.thumbnails?.default?.url ?? null,
          medium: sn.thumbnails?.medium?.url ?? null,
          high: sn.thumbnails?.high?.url ?? null
        }
      });
    }
    pageToken = json.nextPageToken;
    await sleep(150); // sanftes Rate-Limiting
    if (items.length >= max) break;
  } while (pageToken);
  return items;
}

function writeJSON(file, data) {
  const json = JSON.stringify(data, null, 2) + "\n";
  fs.writeFileSync(file, json, "utf8");
}

async function main() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

  const playlistsOutput = [];
  for (const p of SOURCES.playlists) {
    const playlistId = p.id;
    console.log(`→ Fetch playlist meta: ${playlistId}`);
    const meta = await fetchPlaylistMeta(playlistId);
    if (!meta) { console.warn(`⚠️ No meta for playlist ${playlistId}`); continue; }
    playlistsOutput.push({ ...meta, mentor: p.mentor ?? null });

    console.log(`→ Fetch videos for ${playlistId}`);
    const videos = await fetchAllPlaylistItems(playlistId);
    const out = { playlistId, fetchedAt: new Date().toISOString(), count: videos.length, videos };
    writeJSON(path.join(DATA_DIR, `videos_${playlistId}.json`), out);
  }

  writeJSON(path.join(DATA_DIR, "playlists.json"), {
    fetchedAt: new Date().toISOString(),
    playlists: playlistsOutput
  });

  console.log("✅ Done. Data written to /data");
}

main().catch((e) => { console.error("❌ Failed:", e); process.exit(1); });
