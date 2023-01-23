const spawn = require("child_process").spawn;
const WebSocketServer = require("ws").WebSocketServer;

const wss = new WebSocketServer({port: 8080});
wss.on("connection", (ws) => {
    ws.on("message", (data) => {
        const process = spawn("swipl", ["-s", "chess.pl", "-g", data, "-t", "halt"]);
        process.stdout.setEncoding("utf8");
        process.stdout.on("data", (data) => {
            ws.send(data.toString());
            ws.close();
        });
        process.stderr.on("data", (data) => console.log("stderr: " + data));
    });
    ws.on("error", (error) => console.error("Recieved error: " + error));
});