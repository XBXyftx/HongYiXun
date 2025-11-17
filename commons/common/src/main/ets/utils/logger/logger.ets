/**
 * Copyright (c) 2025 XBXyftx
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { hilog } from '@kit.PerformanceAnalysisKit'

/** 日志标签，用于标识日志来源应用 */
const tag = 'XBXLogger'

/**
 * 日志工具类
 * 
 * 对 HarmonyOS hilog 的业务封装，提供统一的日志输出接口
 * 
 * @remarks
 * 设计目标：
 * - 统一日志格式：确保所有日志输出格式一致
 * - 简化使用：封装 hilog 复杂的参数配置
 * - 便于调试：通过日志级别快速定位问题
 * - 生产追踪：记录关键业务流程和异常信息
 * 
 * 日志级别说明：
 * - debug: 调试信息，开发阶段使用，帮助定位问题
 * - info: 一般信息，记录正常的业务流程
 * - warn: 警告信息，潜在问题或使用非推荐方式
 * - error: 错误信息，业务异常或操作失败
 * 
 * 使用规范：
 * - debug: 详细的变量值、函数调用、执行流程
 * - info: 重要操作的开始/完成、状态变化
 * - warn: 使用默认值、兼容处理、性能警告
 * - error: 网络失败、数据异常、操作中断
 * 
 * 性能考虑：
 * - 日志输出会影响性能，生产环境建议只保留 warn 和 error
 * - 避免在循环中频繁输出日志
 * - 不要输出大量数据或敏感信息
 * 
 * @example
 * ```typescript
 * import { logger, LOG_TAG } from 'common'
 * 
 * // 调试信息
 * logger.debug(`${LOG_TAG.NEWS_MANAGER}开始获取新闻列表`)
 * 
 * // 一般信息
 * logger.info(`${LOG_TAG.NEWS_MANAGER}成功获取 ${count} 条新闻`)
 * 
 * // 警告信息
 * logger.warn(`${LOG_TAG.NEWS_MANAGER}使用缓存数据，网络未连接`)
 * 
 * // 错误信息
 * logger.error(`${LOG_TAG.NEWS_MANAGER}获取新闻失败: ${error.message}`)
 * ```
 * 
 * @see LOG_TAG 日志标签枚举，提供统一的模块标识
 */
class Logger{
  /**
   * 日志领域标识
   * 
   * 用于区分不同业务模块的日志，支持日志过滤
   * 
   * @remarks
   * - 格式：十六进制数值
   * - 范围：0x0000 - 0xFFFF
   * - 建议：每个应用使用唯一的 domain
   * - 本应用使用：0x1234
   * 
   * @private
   */
  private domain:number
  
  /**
   * 日志标签
   * 
   * 用于标识日志来源，便于搜索和过滤
   * 
   * @remarks
   * - 建议使用模块名或功能名作为标签
   * - 配合 LOG_TAG 枚举使用，实现更细粒度的分类
   * - 本应用使用：'XBXLogger'
   * 
   * @private
   */
  private tag:string
  
  /**
   * 日志格式化字符串
   * 
   * 定义日志内容的输出格式
   * 
   * @remarks
   * - %{public}s：公开字符串，不脱敏
   * - %{private}s：私有字符串，生产环境会脱敏
   * - 本应用使用 public，因为不涉及敏感数据
   * 
   * 安全建议：
   * - 用户隐私数据（手机号、身份证）使用 private
   * - 业务数据（新闻标题、配置项）使用 public
   * 
   * @private
   */
  private format:string = '%{public}s'

  /**
   * 构造函数
   * 
   * @param domain - 日志领域标识，默认 0x0000
   * @param tag - 日志标签，默认空字符串
   * 
   * @remarks
   * 通常不需要直接实例化，使用导出的单例 logger 即可
   */
  constructor(domain: number = 0x0000, tag: string = '') {
    this.domain = domain
    this.tag = tag
  }
  
  /**
   * 输出调试级别日志
   * 
   * 用于输出详细的调试信息，帮助开发者追踪程序执行流程
   * 
   * @param args - 日志内容，支持模板字符串
   * 
   * @remarks
   * 使用场景：
   * - 变量值检查：查看关键变量的值
   * - 流程追踪：确认代码执行路径
   * - 状态验证：检查对象状态是否正确
   * 
   * 性能提示：
   * - 开发阶段可大量使用
   * - 生产环境建议关闭或减少
   * 
   * @example
   * ```typescript
   * logger.debug(`${LOG_TAG.NEWS_MANAGER}newsList length: ${newsList.length}`)
   * logger.debug(`${LOG_TAG.NEWS_MANAGER}进入 fetchNews 函数`)
   * ```
   */
  debug(args: string): void {
    hilog.debug(this.domain, this.tag, this.format, args);
  }

  /**
   * 输出信息级别日志
   * 
   * 用于记录一般性的业务信息，标记重要的执行节点
   * 
   * @param args - 日志内容，支持模板字符串
   * 
   * @remarks
   * 使用场景：
   * - 操作完成：数据加载成功、保存完成
   * - 状态变化：用户登录、配置更新
   * - 关键节点：应用启动、模块初始化
   * 
   * @example
   * ```typescript
   * logger.info(`${LOG_TAG.NEWS_MANAGER}成功从服务器获取 ${count} 条新闻`)
   * logger.info(`${LOG_TAG.KV_DATABASE}数据库初始化成功`)
   * ```
   */
  info(args: string): void {
    hilog.info(this.domain, this.tag, this.format, args);
  }

  /**
   * 输出警告级别日志
   * 
   * 用于记录潜在问题或非推荐的操作，但不影响正常功能
   * 
   * @param args - 日志内容，支持模板字符串
   * 
   * @remarks
   * 使用场景：
   * - 使用默认值：配置项不存在，使用默认配置
   * - 兼容处理：数据格式不符，进行容错处理
   * - 性能警告：操作耗时较长
   * - 弃用警告：使用了即将废弃的 API
   * 
   * @example
   * ```typescript
   * logger.warn(`${LOG_TAG.NEWS_MANAGER}本地数据为空，使用默认数据`)
   * logger.warn(`${LOG_TAG.PREFERENCE_DB}配置项 ${key} 发生变化`)
   * ```
   */
  warn(args: string): void {
    hilog.warn(this.domain, this.tag, this.format, args);
  }

  /**
   * 输出错误级别日志
   * 
   * 用于记录错误和异常，表示操作失败或出现问题
   * 
   * @param args - 日志内容，支持模板字符串
   * 
   * @remarks
   * 使用场景：
   * - 网络错误：请求失败、超时
   * - 数据异常：解析失败、类型错误
   * - 业务错误：操作不允许、状态非法
   * - 系统异常：资源不足、权限拒绝
   * 
   * 最佳实践：
   * - 包含错误原因：error.message 或 error.code
   * - 提供上下文：操作名称、相关参数
   * - 便于追踪：包含关键标识符
   * 
   * @example
   * ```typescript
   * logger.error(`${LOG_TAG.NEWS_MANAGER}获取新闻失败: ${error.message}`)
   * logger.error(`${LOG_TAG.KV_DATABASE}数据库初始化失败，code: ${error.code}`)
   * ```
   */
  error(args: string): void {
    hilog.error(this.domain, this.tag, this.format, args);
  }

}

/**
 * 日志工具单例对象
 * 
 * 全局唯一的 Logger 实例，整个应用统一使用
 * 
 * @remarks
 * 配置信息：
 * - domain: 0x1234（应用唯一标识）
 * - tag: 'XBXLogger'（日志来源标识）
 * 
 * 使用方式：
 * - 直接导入使用，无需实例化
 * - 配合 LOG_TAG 枚举提供模块信息
 * - 支持所有四个日志级别
 * 
 * @example
 * ```typescript
 * import { logger, LOG_TAG } from 'common'
 * 
 * logger.info(`${LOG_TAG.APP_INIT}应用启动成功`)
 * logger.error(`${LOG_TAG.NEWS_API}网络请求失败`)
 * ```
 */
export const logger:Logger = new Logger(0x1234,tag)
