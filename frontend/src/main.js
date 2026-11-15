// Ponto de entrada JavaScript. O Vite começa por aqui (veja index.html).
import "./style.css";

// O vite-plugin-elm permite importar um módulo Elm como se fosse JS: ele
// compila src/Main.elm e recompila a cada alteração (hot reload).
import { Elm } from "./Main.elm";

Elm.Main.init({ node: document.getElementById("app") });
