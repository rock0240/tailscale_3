const http = require("http");

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", service: "tailscale-node" }));
  } else {
    res.writeHead(200, { "Content-Type": "text/html" });
    res.end("<h1>Tailscale Node is Active</h1><p>Keeping the container alive.</p>");
  }
});

server.listen(PORT, () => {
  console.log(`Keep-alive server listening on port ${PORT}`);
});
