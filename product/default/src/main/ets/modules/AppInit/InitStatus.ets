/**
 * 初始化状态接口
 *
 * 定义各个模块的初始化状态结构
 *
 * @interface
 */
export interface InitStatus {
  /** 数据库模块初始化状态 */
  databases: boolean;
  /** 用户配置初始化状态 */
  userConfig: boolean;
  /** 业务管理器初始化状态 */
  managers: boolean;
  /** AppStorageV2 初始化状态 */
  appStorageV2: boolean;
  /** Markdown 配置初始化状态 */
  markdown: boolean;
}