const crypto = require('node:crypto');

function bytesToHex(bytes) {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
}

function createUuidV7(date = new Date()) {
  const unixMillis = BigInt(date.getTime());
  const random = crypto.randomBytes(10);

  const timeHex = unixMillis.toString(16).padStart(12, '0');
  const randomHex = bytesToHex(random);

  const segment1 = timeHex.slice(0, 8);
  const segment2 = timeHex.slice(8, 12);
  const segment3 = `7${randomHex.slice(0, 3)}`;

  const variantNibble = (parseInt(randomHex[3], 16) & 0x3) | 0x8;
  const segment4 = `${variantNibble.toString(16)}${randomHex.slice(4, 7)}`;
  const segment5 = randomHex.slice(7, 19);

  return `${segment1}-${segment2}-${segment3}-${segment4}-${segment5}`;
}

module.exports = {
  createUuidV7
};
