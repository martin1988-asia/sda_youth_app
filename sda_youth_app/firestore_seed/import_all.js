const { execSync } = require("child_process");

const scripts = [
  "import_devotionals.js",
  "import_events.js",
  "import_groups.js",
  "import_posts.js",
  "import_lessons.js",
  "import_announcements.js",
  "import_profiles.js"
  // Bible import scripts will be added later
];

for (const script of scripts) {
  console.log(`\n=== Running ${script} ===`);
  try {
    execSync(`node firestore_seed/${script}`, { stdio: "inherit" });
    console.log(`=== Finished ${script} ===\n`);
  } catch (err) {
    console.error(`Error running ${script}:`, err);
    break; // stop if something fails
  }
}

console.log("✅ All imports complete!");
