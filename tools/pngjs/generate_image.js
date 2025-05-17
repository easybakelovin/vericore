/*
Convert png images to hex file for loading onto FPGA.
Image must be 128 x 64 pixels in size.

If transparency value is less than 50%, pixel will be considered off (can be adjusted).
*/

const fs = require("fs");            // Load file system package
const PNG = require("pngjs").PNG();  // Load pngjs package

fs.createReadStream("image.png") // Load image.png
    .pipe(new PNG())             // Pipe it to PNG instance from pngjs lib
    .on("parsed", function(){
        const bytes =[]; // Declaration of variable to hold byte data

        // Iterate over the vertical lines
        for (var y = 0; y < this.height; y+=8) {
            // Iterate through all the columns 
            for (var x = 0; x < this.width; x+=1){
                let byte = 0;
                // Go through each of the 8 pixels of vertical column
                // Start at last bit to simply just shift each bit in bytes from the right
                for (var j = 7; j>=0; j-=1){
                    let idx = (this.width * (y+j) + x) * 4; // Get index for current pixel
                    /*
                    this.data is a long array of bytes where for each pixel we have 4 bytes, 
                    one for red, one for green, one for blue and one for the alpha channel. 
                    So the first line calculates this offset by figuring out which byte we are, 
                    this is the number of complete rows (or y offset) multiplied by 128 (the 
                    screen width) plus the current x offset. We then multiply by 4 since each 
                    pixel is 4 bytes (RGBA).
                    */
                    if (this.data[idx+3] > 128){ // if transparency byte < 128 consider the pixel off
                        byte = (byte << 1) + 1;
                    } else {
                        byte = (byte << 1) + 0;
                    }
            }
            bytes.push(byte); // Store byte in bytes
        }
    }
    // Take bytes and convert them to hex. Pad from left so each byte is exactly 2 hex chars
    const hexData = bytes.map((b) => b.toString('16').padStart(2, '0'));
    // Output hex data into a file called image.hex separating each hex byte with a space.
    fs.writeFileSync('image.hex', hexData.join(' '));
});