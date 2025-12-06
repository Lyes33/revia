import { ESLint } from 'eslint';

interface Issue {
  file: string;
  line: number;
  message: string;
}

const formatter = (results: ESLint.LintResult[]): Issue[] => {
  const issues: Issue[] = [];

  results.forEach((result) => {
    result.messages.forEach((msg) => {
      // Variables ou fonctions jamais utilisées
      if (msg.ruleId === '@typescript-eslint/no-unused-vars') {
        issues.push({
          file: result.filePath,
          line: msg.line,
          message: 'Variable définie mais jamais utilisée',
        });
      }

      // CamelCase pour const et let
      if (msg.ruleId === '@typescript-eslint/naming-convention') {
        issues.push({
          file: result.filePath,
          line: msg.line,
          message: msg.message,
        });
      }
    });
  });

  return issues;
};

const run = async () => {
  const eslint = new ESLint({
    overrideConfigFile: '.eslintrc.json', // utilise ton fichier ESLint
    fix: false,
  });

  // Lister les fichiers à analyser
  const files = ['src', 'tests']; // adapte selon ton projet
  const results: ESLint.LintResult[] = [];

  for (const file of files) {
    const res = await eslint.lintFiles([`${file}/**/*.ts`, `${file}/**/*.tsx`]);
    results.push(...res);
  }

  const issues = formatter(results);
  console.log(JSON.stringify(issues, null, 2));
};

run();
