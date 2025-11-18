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
import {
  APP_STORAGE_KEYS, logger, preferenceDB, UserConfigViewModel, LOG_TAG, kvDatabase
} from "common";
import { common } from "@kit.AbilityKit";
import { colorModManager, newsManager, userConfigManager } from "feature";
import { AppStorageV2, promptAction } from "@kit.ArkUI";
import { lvCode, lvText } from "@luvi/lv-markdown-in";

/**
 * 初始化状态接口
 * 
 * 定义各个模块的初始化状态结构
 * 
 * @interface
 */
interface InitStatus {
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

/**
 * 应用初始化管理类
 * 
 * 负责管理应用启动时各个模块的初始化流程，采用分阶段初始化策略
 * 
 * @remarks
 * 初始化阶段设计：
 * 
 * **阶段 1 - 基础模块初始化（onCreate）**
 * - 数据库初始化：KVDatabase、PreferenceDB
 * - 用户配置加载：从持久化存储恢复配置
 * - 业务管理器初始化：NewsManager 等
 * 
 * **阶段 2 - 窗口相关初始化（onWindowStageCreate）**
 * - AppStorageV2 初始化：窗口宽度等全局状态
 * - 主题管理器初始化：ColorModManager（依赖 ApplicationContext）
 * 
 * **阶段 3 - UI 依赖初始化（页面加载后）**
 * - Markdown 配置：依赖 AppStorageV2 中的用户配置
 * - 其他 UI 相关配置
 * 
 * 初始化顺序的重要性：
 * - AppStorageV2 必须在 Window 创建后才能使用
 * - 用户配置需要先从 PreferenceDB 加载再同步到 AppStorageV2
 * - Markdown 配置依赖 AppStorageV2 中的字体大小设置
 * 
 * @example
 * ```typescript
 * // 在 EntryAbility 中使用
 * class EntryAbility extends UIAbility {
 *   // 阶段 1：基础初始化
 *   onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
 *     appInit.initPhase1_BaseModules(this.context)
 *   }
 * 
 *   // 阶段 2：窗口初始化
 *   onWindowStageCreate(windowStage: window.WindowStage): void {
 *     appInit.initPhase2_WindowRelated(this.context.getApplicationContext())
 *     
 *     windowStage.loadContent('pages/StartPage', (err) => {
 *       if (!err.code) {
 *         // 阶段 3：UI 依赖初始化
 *         appInit.initPhase3_UIDependent()
 *       }
 *     })
 *   }
 * }
 * ```
 * 
 * @see EntryAbility 应用入口，协调初始化流程
 */
export class AppInit {
  /**
   * 初始化状态追踪
   * 
   * 记录各个模块的初始化状态，便于调试和错误定位
   * 
   * @private
   */
  private initStatus: InitStatus = {
    databases: false,        // 数据库初始化状态
    userConfig: false,       // 用户配置初始化状态
    managers: false,         // 管理器初始化状态
    appStorageV2: false,     // AppStorageV2 初始化状态
    markdown: false          // Markdown 初始化状态
  }

  // ==================== 阶段 1：基础模块初始化 ====================

  /**
   * 阶段 1：基础模块初始化
   * 
   * 在 EntryAbility.onCreate() 中调用，初始化不依赖窗口的基础模块
   * 
   * @param uiAbilityContext - UIAbility 上下文对象
   * @returns Promise<boolean> - 初始化是否成功
   * 
   * @remarks
   * 初始化内容：
   * 1. 数据库模块（KV数据库、偏好设置数据库）
   * 2. 用户配置加载（从持久化存储恢复）
   * 3. 业务管理器（新闻管理器等）
   * 4. 数据预加载（新闻列表、轮播图）
   * 
   * 调用时机：
   * - 应用启动的最早阶段
   * - 在创建窗口之前
   * - 在访问 UI 之前
   * 
   * 注意事项：
   * - 此阶段不能访问 AppStorageV2
   * - 不能进行 UI 操作
   * - 应尽快完成，避免阻塞启动
   * 
   * @example
   * ```typescript
   * onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
   *   appInit.initPhase1_BaseModules(this.context).then(success => {
   *     if (success) {
   *       logger.info('基础模块初始化成功')
   *     } else {
   *       logger.error('基础模块初始化失败，应用可能无法正常运行')
   *     }
   *   })
   * }
   * ```
   */
  async initPhase1_BaseModules(uiAbilityContext: common.UIAbilityContext): Promise<boolean> {
    logger.info(`${LOG_TAG.APP_INIT}========== 开始阶段 1：基础模块初始化 ==========`)
    
    try {
      // 步骤 1：初始化数据库
      logger.info(`${LOG_TAG.APP_INIT}步骤 1/4：初始化数据库模块...`)
      const dbInitSuccess = await this.initDatabases(uiAbilityContext)
      if (!dbInitSuccess) {
        logger.error(`${LOG_TAG.APP_INIT}✗ 数据库初始化失败，终止初始化流程 - 请检查应用权限和存储空间`)
        return false
      }
      
      // 步骤 2：加载用户配置
      logger.info(`${LOG_TAG.APP_INIT}步骤 2/4：加载用户配置...`)
      const configInitSuccess = this.initUserConfig(uiAbilityContext)
      if (!configInitSuccess) {
        logger.warn(`${LOG_TAG.APP_INIT}用户配置初始化失败，将使用默认配置`)
        // 配置加载失败不影响应用运行，继续执行
      }
      
      // 步骤 3：初始化业务管理器
      logger.info(`${LOG_TAG.APP_INIT}步骤 3/4：初始化业务管理器...`)
      const managersInitSuccess = await this.initManagers(uiAbilityContext)
      if (!managersInitSuccess) {
        logger.error(`${LOG_TAG.APP_INIT}✗ 管理器初始化失败 - 应用可继续运行但新闻功能不可用`)
        // 管理器初始化失败不终止流程，允许应用继续启动
        // return false
      }
      
      // 步骤 4：预加载数据
      logger.info(`${LOG_TAG.APP_INIT}步骤 4/4：预加载应用数据...`)
      await this.preloadData()
      
      logger.info(`${LOG_TAG.APP_INIT}========== 阶段 1 完成：基础模块初始化成功 ==========`)
      return true
      
    } catch (error) {
      logger.error(`${LOG_TAG.APP_INIT}✗ 阶段 1 初始化异常 - 详细信息：${JSON.stringify(error)}`)
      promptAction.openToast({ message: '应用初始化失败，请重启应用' })
      return false
    }
  }

  /**
   * 初始化数据库模块
   * 
   * 初始化 KV 数据库和偏好设置数据库
   * 
   * @param context - UIAbility 上下文
   * @returns Promise<boolean> - 是否初始化成功
   * 
   * @remarks
   * 初始化顺序：
   * 1. KV 数据库：用于缓存业务数据（新闻列表等）
   * 2. 偏好设置数据库：用于存储用户配置
   * 
   * 失败处理：
   * - KV 数据库失败：可能影响离线功能
   * - 偏好设置失败：会使用默认配置
   * 
   * @private
   */
  private async initDatabases(context: common.UIAbilityContext): Promise<boolean> {
    // 初始化 KV 数据库
    const kvInitSuccess = kvDatabase.init(context)
    if (kvInitSuccess) {
      logger.info(`${LOG_TAG.APP_INIT}✓ KV 数据库初始化成功`)
      this.initStatus.databases = true
    } else {
      logger.error(`${LOG_TAG.APP_INIT}✗ KV 数据库初始化失败 - 原因：KVManager 创建失败或 context 无效`)
      return false
    }
    
    // 初始化偏好设置数据库
    const preferenceInitSuccess = preferenceDB.init(context)
    if (preferenceInitSuccess) {
      logger.info(`${LOG_TAG.APP_INIT}✓ 偏好设置数据库初始化成功`)
    } else {
      logger.error(`${LOG_TAG.APP_INIT}✗ 偏好设置数据库初始化失败 - 原因：Preferences 实例创建失败`)
      return false
    }
    
    return true
  }

  /**
   * 初始化用户配置
   * 
   * 从偏好设置数据库加载用户配置，恢复用户的个性化设置
   * 
   * @param context - UIAbility 上下文
   * @returns boolean - 是否初始化成功
   * 
   * @remarks
   * 配置内容：
   * - 字体大小（FONT_SIZE）
   * - 颜色模式（COLOR_MODE）
   * 
   * 数据流：
   * PreferenceDB → UserConfigManager → 内存状态
   * 
   * 注意：此阶段还不能同步到 AppStorageV2，因为窗口还未创建
   * 
   * @private
   */
  private initUserConfig(context: common.UIAbilityContext): boolean {
    try {
      const syncSuccess = userConfigManager.syncDataToAppStorage()
      if (syncSuccess) {
        logger.info(`${LOG_TAG.APP_INIT}✓ 用户配置加载成功`)
        this.initStatus.userConfig = true
        return true
      } else {
        logger.warn(`${LOG_TAG.APP_INIT}⚠ 用户配置加载失败 - 原因：PreferenceDB 数据读取失败，将使用默认配置`)
        return false
      }
    } catch (error) {
      logger.error(`${LOG_TAG.APP_INIT}✗ 用户配置加载异常 - 原因：${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 初始化业务管理器
   * 
   * 初始化各个业务模块的管理器
   * 
   * @param context - UIAbility 上下文
   * @returns Promise<boolean> - 是否初始化成功
   * 
   * @remarks
   * 管理器列表：
   * - NewsManager：新闻数据管理
   * - 其他业务管理器...
   * 
   * 注意：ColorModManager 依赖 ApplicationContext，在阶段 2 初始化
   * 
   * @private
   */
  private async initManagers(context: common.UIAbilityContext): Promise<boolean> {
    try {
      // 初始化新闻管理器
      const newsManagerInitSuccess = await newsManager.init(context)
      if (newsManagerInitSuccess) {
        logger.info(`${LOG_TAG.APP_INIT}✓ 新闻管理器初始化成功`)
        this.initStatus.managers = true
        return true
      } else {
        logger.error(`${LOG_TAG.APP_INIT}✗ 新闻管理器初始化失败 - 原因：无法获取 KV 数据库实例`)
        return false
      }
    } catch (error) {
      logger.error(`${LOG_TAG.APP_INIT}✗ 管理器初始化异常 - 原因：${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 预加载应用数据
   * 
   * 在后台预加载必要的数据，提升用户体验
   * 
   * @remarks
   * 预加载策略：
   * - 异步执行，不阻塞主流程
   * - 失败不影响应用启动
   * - 优先加载用户可能立即需要的数据
   * 
   * 预加载内容：
   * - 新闻文章列表
   * - 轮播图数据
   * 
   * @private
   */
  private async preloadData(): Promise<void> {
    try {
      // 异步更新新闻数据，不阻塞启动流程
      Promise.all([
        newsManager.updateNewsListToDB(),
        newsManager.updateNewsSwiperToDB()
      ]).then(() => {
        logger.info(`${LOG_TAG.APP_INIT}数据预加载完成`)
      }).catch((error: Error) => {
        logger.warn(`${LOG_TAG.APP_INIT}数据预加载失败: ${JSON.stringify(error)}，将使用缓存数据`)
      })
    } catch (error) {
      logger.warn(`${LOG_TAG.APP_INIT}数据预加载异常: ${JSON.stringify(error)}`)
    }
  }

  // ==================== 阶段 2：窗口相关初始化 ====================

  /**
   * 阶段 2：窗口相关初始化
   * 
   * 在 EntryAbility.onWindowStageCreate() 中调用，初始化依赖窗口的模块
   * 
   * @param applicationContext - 应用上下文对象
   * @returns boolean - 初始化是否成功
   * 
   * @remarks
   * 初始化内容：
   * 1. 颜色模式管理器（需要 ApplicationContext 来设置系统主题）
   * 2. 其他依赖窗口的初始化
   * 
   * 调用时机：
   * - 在窗口创建后
   * - 在加载页面之前
   * - AppStorageV2 可用之后
   * 
   * 前置条件：
   * - 阶段 1 必须成功完成
   * - Window 对象已创建
   * 
   * @example
   * ```typescript
   * onWindowStageCreate(windowStage: window.WindowStage): void {
   *   // 初始化窗口相关模块
   *   appInit.initPhase2_WindowRelated(this.context.getApplicationContext())
   *   
   *   // 加载页面
   *   windowStage.loadContent('pages/StartPage', ...)
   * }
   * ```
   */
  initPhase2_WindowRelated(applicationContext: common.ApplicationContext): boolean {
    logger.info(`${LOG_TAG.APP_INIT}========== 开始阶段 2：窗口相关初始化 ==========`)
    
    try {
      // 初始化颜色模式管理器
      logger.info(`${LOG_TAG.APP_INIT}初始化颜色模式管理器...`)
      const colorModInitSuccess = colorModManager.init(applicationContext)
      if (colorModInitSuccess) {
        logger.info(`${LOG_TAG.APP_INIT}✓ 颜色模式管理器初始化成功`)
        this.initStatus.appStorageV2 = true
      } else {
        logger.warn(`${LOG_TAG.APP_INIT}⚠ 颜色模式管理器初始化失败 - 原因：ApplicationContext 无效，将使用默认主题`)
        // 不影响应用运行
      }
      
      logger.info(`${LOG_TAG.APP_INIT}========== 阶段 2 完成：窗口相关初始化成功 ==========`)
      return true
      
    } catch (error) {
      logger.error(`${LOG_TAG.APP_INIT}阶段 2 初始化异常: ${JSON.stringify(error)}`)
      return false
    }
  }

  // ==================== 阶段 3：UI 依赖初始化 ====================

  /**
   * 阶段 3：UI 依赖模块初始化
   * 
   * 在页面加载完成后调用，初始化依赖 AppStorageV2 的模块
   * 
   * @remarks
   * 初始化内容：
   * - Markdown 配置：需要从 AppStorageV2 获取用户字体大小设置
   * - 其他 UI 相关配置
   * 
   * 调用时机：
   * - 在 windowStage.loadContent() 的回调中
   * - AppStorageV2 已完全可用
   * - 在显示首页之前
   * 
   * 独立性：
   * - 此方法保持独立，方便单独调用
   * - 可在需要时重新配置 Markdown
   * - 不影响其他初始化流程
   * 
   * 前置条件：
   * - 阶段 1 和阶段 2 必须完成
   * - AppStorageV2 中的 USER_CONFIG 必须已初始化
   * 
   * @example
   * ```typescript
   * windowStage.loadContent('pages/StartPage', (err) => {
   *   if (err.code) {
   *     hilog.error(DOMAIN, 'testTag', '页面加载失败: %{public}s', JSON.stringify(err))
   *     return
   *   }
   *   
   *   // 页面加载成功，初始化 UI 依赖模块
   *   appInit.initPhase3_UIDependent()
   * })
   * ```
   */
  initPhase3_UIDependent(): boolean {
    logger.info(`${LOG_TAG.APP_INIT}========== 开始阶段 3：UI 依赖模块初始化 ==========`)
    
    try {
      // 初始化 Markdown 配置
      logger.info(`${LOG_TAG.APP_INIT}初始化 Markdown 配置...`)
      const markdownInitSuccess = this.markDownConfigInit()
      if (markdownInitSuccess) {
        logger.info(`${LOG_TAG.APP_INIT}✓ Markdown 配置初始化成功`)
      } else {
        logger.warn(`${LOG_TAG.APP_INIT}⚠ Markdown 配置初始化失败 - 原因：无法从 AppStorageV2 获取用户配置，将使用默认配置`)
      }
      
      logger.info(`${LOG_TAG.APP_INIT}========== 阶段 3 完成：UI 依赖模块初始化成功 ==========`)
      
      return true
      
    } catch (error) {
      logger.error(`${LOG_TAG.APP_INIT}阶段 3 初始化异常: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 配置 Markdown 渲染引擎
   * 
   * 根据用户的字体大小设置配置 Markdown 渲染参数
   * 
   * @returns boolean - 配置是否成功
   * 
   * @remarks
   * 配置内容：
   * - 代码块行号显示：启用行号
   * - 文本基础字体大小：使用用户设置的字体大小
   * 
   * 依赖关系：
   * - 依赖 AppStorageV2 中的 USER_CONFIG
   * - 必须在 AppStorageV2 初始化后调用
   * 
   * 独立性说明：
   * - 此方法可以独立调用
   * - 用户修改字体大小后可重新调用此方法
   * - 不影响其他初始化流程
   * 
   * 使用的第三方库：
   * - @luvi/lv-markdown-in: Markdown 渲染引擎
   * 
   * @example
   * ```typescript
   * // 应用启动时初始化
   * appInit.markDownConfigInit()
   * 
   * // 用户修改字体大小后重新配置
   * userConfig.fontSize = 18
   * appInit.markDownConfigInit() // 重新应用配置
   * ```
   */
  markDownConfigInit(): boolean {
    try {
      // 从 AppStorageV2 获取用户字体大小设置
      const userConfig = AppStorageV2.connect(
        UserConfigViewModel,
        APP_STORAGE_KEYS.USER_CONFIG,
        () => new UserConfigViewModel()
      )
      
      if (!userConfig) {
        logger.error(`${LOG_TAG.APP_INIT}✗ 无法获取用户配置 - 原因：AppStorageV2 中不存在 USER_CONFIG，Markdown 使用默认字体大小`)
        return false
      }
      
      const baseFontSize = userConfig.fontSize
      
      // 配置 Markdown 渲染引擎
      lvCode.setIndexState(true)           // 启用代码块行号
      lvText.setTextSize(baseFontSize)     // 设置文本基础字体大小
      
      logger.info(`${LOG_TAG.APP_INIT}✓ Markdown 配置成功，字体大小: ${baseFontSize}`)
      this.initStatus.markdown = true
      
      return true
      
    } catch (error) {
      logger.error(`${LOG_TAG.APP_INIT}✗ Markdown 配置异常 - 原因：${JSON.stringify(error)}`)
      return false
    }
  }

  // ==================== 工具方法 ====================

  /**
   * 打印初始化状态
   * 
   * 用于调试和问题诊断，输出各模块的初始化状态
   * 
   * @remarks
   * - 成功的模块使用 info 级别
   * - 失败的模块使用 warn 级别，便于快速定位问题
   * 
   * @public
   */
  printInitStatus(): void {
    logger.info(`${LOG_TAG.APP_INIT}========== 初始化状态报告 ==========`)
    
    // 数据库模块
    if (this.initStatus.databases) {
      logger.info(`${LOG_TAG.APP_INIT}[数据库模块] ✓ 初始化成功`)
    } else {
      logger.warn(`${LOG_TAG.APP_INIT}[数据库模块] ✗ 初始化失败 - 影响：离线功能可能不可用`)
    }
    
    // 用户配置
    if (this.initStatus.userConfig) {
      logger.info(`${LOG_TAG.APP_INIT}[用户配置] ✓ 初始化成功`)
    } else {
      logger.warn(`${LOG_TAG.APP_INIT}[用户配置] ✗ 初始化失败 - 影响：将使用默认配置（字体16、跟随系统主题）`)
    }
    
    // 业务管理器
    if (this.initStatus.managers) {
      logger.info(`${LOG_TAG.APP_INIT}[业务管理器] ✓ 初始化成功`)
    } else {
      logger.warn(`${LOG_TAG.APP_INIT}[业务管理器] ✗ 初始化失败 - 影响：新闻数据功能不可用，请检查网络或数据库`)
    }
    
    // AppStorageV2
    if (this.initStatus.appStorageV2) {
      logger.info(`${LOG_TAG.APP_INIT}[AppStorageV2] ✓ 初始化成功`)
    } else {
      logger.warn(`${LOG_TAG.APP_INIT}[AppStorageV2] ✗ 初始化失败 - 影响：主题切换功能可能不可用`)
    }
    
    // Markdown 配置
    if (this.initStatus.markdown) {
      logger.info(`${LOG_TAG.APP_INIT}[Markdown配置] ✓ 初始化成功`)
    } else {
      logger.warn(`${LOG_TAG.APP_INIT}[Markdown配置] ✗ 初始化失败 - 影响：文章渲染使用默认字体`)
    }
    
    logger.info(`${LOG_TAG.APP_INIT}======================================`)
  }

  /**
   * 获取初始化状态
   * 
   * 供外部查询初始化状态
   * 
   * @returns 初始化状态对象的只读副本
   * 
   * @remarks
   * 返回初始化状态的深拷贝，避免外部修改内部状态
   */
  getInitStatus(): InitStatus {
    return {
      databases: this.initStatus.databases,
      userConfig: this.initStatus.userConfig,
      managers: this.initStatus.managers,
      appStorageV2: this.initStatus.appStorageV2,
      markdown: this.initStatus.markdown
    }
  }

  /**
   * 检查是否完全初始化
   * 
   * @returns boolean - 所有模块是否都初始化成功
   * 
   * @remarks
   * 检查所有初始化状态是否都为 true
   */
  isFullyInitialized(): boolean {
    return this.initStatus.databases &&
           this.initStatus.userConfig &&
           this.initStatus.managers &&
           this.initStatus.appStorageV2 &&
           this.initStatus.markdown
  }
}

/**
 * 应用初始化管理器单例
 * 
 * 全局唯一的 AppInit 实例，在 EntryAbility 中使用
 * 
 * @remarks
 * 使用示例：
 * ```typescript
 * import { appInit } from '../init/AppInit'
 * 
 * // 在 EntryAbility 中按阶段调用
 * onCreate() { appInit.initPhase1_BaseModules(this.context) }
 * onWindowStageCreate() { appInit.initPhase2_WindowRelated(...) }
 * // 页面加载后 { appInit.initPhase3_UIDependent() }
 * ```
 */
export const appInit = new AppInit()
