/*
From Lushay Labs tutorial
https://lushaylabs.com/tutorials/2023/03/06/bitfontmakerjs.html

This script converts the font data from the bitfontmakerjs output into a hex file.

Please generate json file from the follwing website:
https://www.pentacom.jp/pentacom/bitfontmaker2/editfont.php?id=4677&ref=learn.lushaylabs.com
*/

const fs = require('fs');

const bitmaps = fs.readFileSync('./monogram-bitmap.json');
const json = JSON.parse(bitmaps.toString());

const memory = [];

for(var i = 32; i <= 126; i++){
    const key = i.toString();
    const horizontalBytes = json[key];
    const verticalBytes = [];

    for (let x = 0; x < 8; x++) {
        let b1 = 0;
        let b2 = 0;
        for (let y = 0; y < 8; y++) {
            if (!horizontalBytes) { continue;}
            const num1 = horizontalBytes[y];
            const num2 = horizontalBytes[y + 8] || 0;
            const bit = (1 << x);
            if ((num1 & bit) !== 0) {
                b1 |= (1 << y);
            }
            if ((num2 & bit) !== 0) {
                b2 |= (1 << y);
            }
        }
        memory.push(b1.toString(16).padStart(2, '0'));
        memory.push(b2.toString(16).padStart(2, '0'));
    }
}
fs.writeFileSync('font.hex', memory.join(' '));