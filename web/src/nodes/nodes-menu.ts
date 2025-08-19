export const nodes_menu = [
  {
    label: '通用', icon: 'pi pi-box', root: true,
    items: [
      [
        {
          label: '参数',
          items: [{ type: "flow_params", }]
        }
      ],
      [
        {
          label: '文件处理',
          items: [{ type: 'file_compress' }]
        }
      ],
      [
        {
          label: '文件传输',
          items: [{ type: "ftp_transfer" }]
        }
      ],
      [
        {
          label: '云端传输',
          items: [{ type: "upload_cos" }, { type: "send_email" }]
        }
      ],
    ]
  },
  {
    label: '数据流',
    icon: 'pi pi-mobile',
    root: true,
    items: [
      [
        {
          label: '输入',
          items: [{ type: "input_file" }, { type: "input_mysql" }, { type: "input_hdfs" }, { type: "input_kafka" }, { type: "input_cos" }]
        }
      ],
      [
        {
          label: '中间件',
          items: [{ type: 'data_filter' }, { type: 'data_order' }, { type: 'data_transition' }]
        }
      ],
      [
        {
          label: '聚合',
          items: [{ type: 'data_merge' }]
        }
      ],
      [
        {
          label: '输出',
          items: [{ type: "output_file" }, { type: "output_mysql" }, { type: "output_hdfs" }, { type: "output_kafka" }]
        }
      ]
    ]
  },
  {
    label: '数据库操作',
    icon: 'pi pi-database',
    root: true,
    items: [
      [
        {
          label: 'SQL执行',
          items: [{ type: "execute_sql" }]
        }
      ]
    ]
  },
  {
    label: 'API处理',
    icon: 'pi pi-clock',
    root: true,
    items: [
      [
        {
          label: 'API调用',
          items: [{ label: 'Kits' }, { label: 'Shoes' }, { label: 'Shorts' }, { label: 'Training' }]
        }
      ],
      [
        {
          label: '自定义拉取',
          items: [{ label: 'Accessories' }, { label: 'Shoes' }, { label: 'T-Shirts' }, { label: 'Shorts' }]
        }
      ],
      [
        {
          label: '爬虫',
          items: [{ label: 'Kickboard' }, { label: 'Nose Clip' }, { label: 'Swimsuits' }, { label: 'Paddles' }]
        }
      ],
    ]
  }
]
