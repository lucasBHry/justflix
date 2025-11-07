const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type'],
    }));
app.use(express.json());

const VIDEOS_PATH = path.join(__dirname, 'data', 'videos.json');

function readVideos() {
    const raw = fs.readFileSync(VIDEOS_PATH, 'utf8');
    return JSON.parse(raw);
}

// GET /api/videolist -> lista básica (id, topic, duration, thumbnail)
app.get('/api/videolist', (req, res) => {
    const all = readVideos();
    const basic = all.map(v => ({
    id: v.id,
    topic: v.topic,
    duration: v.duration,
    thumbnail: v.thumbnail
    }));
    res.json(basic);
});

// GET /api/videolist/topic/:topic -> lista completa por topic
app.get('/api/videolist/topic/:topic', (req, res) => {
    const topic = req.params.topic;
    const all = readVideos();
    const filtered = all.filter(v => v.topic === topic);
    res.json(filtered);
});

// GET /api/videolist/id/:id -> objeto completo por id
app.get('/api/videolist/id/:id', (req, res) => {
    const id = req.params.id;
    const all = readVideos();
    const found = all.find(v => v.id === id);
    if (!found) return res.status(404).json({ error: 'Video not found' });
    res.json(found);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`API server listening on http://localhost:${PORT}`);
});
