const fs = require('fs');
const path = require('path');

const functionRoot = 'packages/tcb-functions';

const functions = [
  require('../packages/tcb-functions/server/fans.tcb.function.rc'),
];

// CloudBase CLI 配置信息
const cli = {
  version: "2.0",
  envId: "{{env.ENV_ID}}",
  functionRoot,
  functions: Object.values(functions),
};

const framework = {
  name: 'fans',
};

const config = { ...cli, framework };
const data = JSON.stringify(config, null, 2);

fs.writeFileSync(path.resolve(__dirname, '..', 'cloudbaserc.json'), data);
