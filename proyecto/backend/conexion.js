const dotenv = require('dotenv');
dotenv.config();

const dbuser = process.env.DB_USER;
const dbpassword = process.env.DB_PASSWORD
const dbname = process.env.DB_NAME;
const dbcluster = process.env.DB_CLUSTER;

const conexion = `mongodb+srv://${dbuser}:${dbpassword}@${dbcluster}/${dbname}`;
module.exports = conexion;