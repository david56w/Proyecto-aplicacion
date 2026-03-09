const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const usuarios = [];

app.post('/registro', (req, es) => {
    const { email, password } = req.body;
    usuarios.push({ email, password });
    console.log("Usuario registrado!:", email);
    res.json({ mensaje: "Usuario creado con exito" });
});

app.post('/login', (req, res) => {
    const { email, password } = req.body;
    const usuarioEncontrado = usuarios.find(u => u.email === email && u.password === password);

    if (usuarioEncontrado) {
        res.status(200).json({ mensaje: "Bienvenido", exito: true});
    } else {
        res.status(401).json({ mensaje: "Credenciales incorrectas", exito: false});
    }
});

app.listen(3000, '0.0.0.0', () => console.log("Backend en puerto 3000"));