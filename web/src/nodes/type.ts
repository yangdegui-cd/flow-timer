
export interface NodeSetting {
  view: {
    name: string,
    icon_type?: "custom" | "prime" | "fortawesome"
    icon: string
    node_type: string,
    node_subtype?: string,
    hide_source?: boolean,
    hide_target?: boolean,
  },
  init: {
    [key: string]: any;
  }
}
