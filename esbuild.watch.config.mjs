import { config } from "./esbuild.common.mjs"
import esbuild from 'esbuild';

const run = async () => {
    const ctx = await esbuild.context(config);
    await ctx.watch();
};
  
run();