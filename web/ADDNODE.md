# 1. 添加对应的setting文件.
## 1.1 src/nodes/setting/ 中添加或修改节点信息
```ts
// 导出节点配置（兼容nodes-setting.ts格式）
// view.icon :节点icon
// view.name : 节点名称
// view.node_type : 节点的前端组件类型.
// view.node_subtype : 节点的类型
// view.hide_source : 是否隐藏源节点
// view.hide_target : 是否隐藏目标节点
// config : 节点的配置项
const execute_sql = {
  view: {
    icon: "pi pi-database",
    name: "执行SQL",
    node_type: "common",
    node_subtype: "execute_sql",
    hide_source: false,
    hide_target: false,
  },
  config: {}

}

export default execute_sql
```

## 1.2 src/data/defaults/nodes.ts 中添加或修改默认值
例如: execute_sql
```ts
export const SQL_EXECUTE_NODE_DEFAULT: ExecuteSqlNodeSetting = {
  connection_type: 'custom',
  custom_connection: {
    name: '',
    type: 'mysql',
    host: '',
    port: 3306,
    username: '',
    password: '',
    description: ''
  },
  catalog: null,
  database: null,
  schema: null,
  sql: '-- 请输入SQL语句\nSELECT 1 AS test_column;',
  timeout: 300,
  max_rows: 1000,
  output_format: 'json',
  save_result: false,
}
```

## 1.3 src/nodes/nodes-setting.ts 中添加或修改节点配置
```ts
const nodes_setting: Record<string, NodeSetting> = {
  data_filter,
  data_merge,
  data_transition,
  data_order,
  flow_params,
  ftp_transfer,
  input_cos,
  input_file,
  input_hdfs,
  input_kafka,
  input_mysql,
  output_file,
  output_hdfs,
  output_kafka,
  output_mysql,
  upload_cos,
  file_compress,
  send_email,
  execute_sql
}
```

## 1.4 src/nodes/nodes-menu.ts 中添加节点

# 2. 添加节点设置编辑组件

## 2.1 src/nodes/view/setting/ 中添加或修改节点前端Setting组件
主键使用 SettingLayout 作为外层样式组件搭配 SettingColumn使用
具体可参考 ParamsSetting.vue

# 3. 添加后端节点执行逻辑

## 3.1 在 app/models/nodes/ 中添加节点类

节点名是 execute_sql 对应类名为 ExecuteSqlNode
节点名是 ftp_transfer 对应类名为 FtpTransferNode

类需要继承 BaseNode 类

可参考 ftp_transfer_node.rb 文件实现
