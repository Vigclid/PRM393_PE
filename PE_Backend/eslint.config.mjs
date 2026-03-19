import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";
import { fileURLToPath } from "url";
import path from "path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default tseslint.config([
  {
    files: ["src/**/*.{ts,js}", "server.ts"],
    ignores: ["eslint.config.mjs"],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        project: path.join(__dirname, "tsconfig.json"),
        tsconfigRootDir: __dirname,
      },
      globals: {
        ...globals.node,
      },
    },
    plugins: {
      "@typescript-eslint": tseslint.plugin,
    },
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    rules: {
      "no-console": "warn",
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-require-imports": "off",
    },
  },
]);
