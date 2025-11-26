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
app.use('/stream', express.static(path.join(__dirname, 'hls')));
const streamRoutes = require('../routes/streamRoutes');
app.use('/hls', streamRoutes);

const VIDEOS_PATH = path.join(__dirname, 'data', 'videos.json');



function readVideos() { 
    const raw = fs.readFileSync(VIDEOS_PATH, 'utf8');
    return JSON.parse(raw);
}
// Leer los videos desde un JSON y devolverlos como objeto



// GET (id, topic, duration, thumbnail)
app.get('/api/videolist', (req, res) => {
    const all = readVideos();
    const basic = all.map(v => ({
    id: v.id,
    topic: v.topic,
    description: v.description,
    duration: v.duration,
    thumbnail: v.thumbnail
    }));
    res.json(basic);
});

// GET lista completa por topic
app.get('/api/videolist/topic/:topic', (req, res) => {
    const topic = req.params.topic;
    const all = readVideos();
    const filtered = all.filter(v => v.topic === topic);
    res.json(filtered);
});

// GET objeto completo por id
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
