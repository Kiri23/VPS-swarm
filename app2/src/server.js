const express = require("express");
const app = express();

app.get("/", (req, res) => {
  res.send("Hello from App 2!");
});

app.listen(3000, () => {
  console.log("App 2 is running on port 3000");
});
