import { config } from "./esbuild.common.mjs"
import esbuild from 'esbuild';

esbuild.build(config).catch(() => process.exit(1))
