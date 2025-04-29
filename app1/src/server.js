const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Hello World! This is a new deployment with updated message.");
});

app.listen(3000, () => {
  console.log("Server is running on port 3000 with updated message");
});
