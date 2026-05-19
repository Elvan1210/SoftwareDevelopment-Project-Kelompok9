const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, '../../frontend/lib');

function walkDir(currentPath, callback) {
  const files = fs.readdirSync(currentPath);
  for (const file of files) {
    const filePath = path.join(currentPath, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      walkDir(filePath, callback);
    } else if (stat.isFile() && file.endsWith('.dart')) {
      callback(filePath);
    }
  }
}

let modifiedCount = 0;

console.log('Starting system-wide visual pop card color overhaul...');

walkDir(libDir, (filePath) => {
  let content = fs.readFileSync(filePath, 'utf8');
  let originalContent = content;

  // Replace dark flat outer color 0xFF131722 with a much brighter, popping slate-indigo color (0xFF1E2538)
  if (content.includes('0xFF131722')) {
    content = content.replace(/0xFF131722/g, '0xFF1E2538');
  }

  // Replace dark flat inner color 0xFF0F1117 with a very rich slate-blue color (0xFF161D2B)
  if (content.includes('0xFF0F1117')) {
    content = content.replace(/0xFF0F1117/g, '0xFF161D2B');
  }

  // Replace dark flat border color 0xFF1F2633 with a popping border color (0xFF2D3A54)
  if (content.includes('0xFF1F2633')) {
    content = content.replace(/0xFF1F2633/g, '0xFF2D3A54');
  }

  // Replace light flat inner color 0xFFF9FAFC with a popping soft periwinkle-blue color (0xFFEEF2FF)
  if (content.includes('0xFFF9FAFC')) {
    content = content.replace(/0xFFF9FAFC/g, '0xFFEEF2FF');
  }

  if (content !== originalContent) {
    fs.writeFileSync(filePath, content, 'utf8');
    modifiedCount++;
    console.log(`Updated: ${path.relative(libDir, filePath)}`);
  }
});

console.log(`UI overhaul complete! Modifed ${modifiedCount} files.`);
process.exit(0);
