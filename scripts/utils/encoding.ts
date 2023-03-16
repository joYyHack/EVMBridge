export const privKey = (hexName: string) => {
  return "0x" + hexName.padEnd(64, "0");
};
