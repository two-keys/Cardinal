import { join } from 'path'
import rails from 'esbuild-rails'
import babelPlugin from '@chialab/esbuild-plugin-babel';

const babelOptions = {filter: /.*/,
    namespace: '',
    config: {
        "targets": "> 10%, not dead"
    }
}

export let config = {
    entryPoints: ["application.js"],
    bundle: true,
    outdir: join(process.cwd(), "app/assets/builds"),
    absWorkingDir: join(process.cwd(), "app/javascript"),
    plugins: [rails(), babelPlugin(babelOptions)],
}