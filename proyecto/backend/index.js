const express = require('express');
const app = express();

const mongoose = require('mongoose');
const conexion = require('./conexion');

app.listen(3000,( ) => {    
    console.log('listening on port 3000');
});

