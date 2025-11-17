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

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window } from '@kit.ArkUI';
import { appInit } from '../init/AppInit';
import { userConfigManager } from 'feature';
import { APP_STORAGE_KEYS, WinWidth, logger, LOG_TAG } from 'common';

/**
 * 日志域标识
 * 
 * 用于 hilog 日志输出，标识日志来源
 */
const DOMAIN = 0x0000;

/**
 * hilog 日志标签
 * 
 * 用于过滤和搜索日志
 */
const TAG = 'EntryAbility';

/**
 * 应用入口 Ability
 * 
 * 作为应用的主入口，负责：
 * - 应用生命周期管理
 * - 应用初始化流程协调
 * - 窗口创建和页面加载
 * - 全局状态管理
 * 
 * @remarks
 * 生命周期方法调用顺序：
 * 1. onCreate(): 应用创建时调用，进行基础初始化
 * 2. onWindowStageCreate(): 窗口创建时调用，初始化 UI 相关模块
 * 3. onForeground(): 应用进入前台
 * 4. onBackground(): 应用进入后台，保存数据
 * 5. onWindowStageDestroy(): 窗口销毁
 * 6. onDestroy(): 应用销毁
 * 
 * 初始化策略：
 * - 分阶段初始化：基础模块 → 窗口模块 → UI 依赖模块
 * - 异步处理：不阻塞主线程
 * - 错误容错：关键模块失败时有降级方案
 * 
 * @see AppInit 应用初始化管理器
 */
export default class EntryAbility extends UIAbility {
  /**
   * 应用创建生命周期回调
   * 
   * 在应用启动时调用，是初始化的第一个阶段
   * 
   * @param want - 启动意图，包含启动参数
   * @param launchParam - 启动参数，包含启动原因等信息
   * 
   * @remarks
   * 初始化内容（阶段 1）：
   * - 数据库初始化（KV数据库、偏好设置数据库）
   * - 用户配置加载
   * - 业务管理器初始化
   * - 数据预加载
   * 
   * 注意事项：
   * - 此时窗口还未创建，不能访问 UI
   * - 不能使用 AppStorageV2
   * - 应快速完成，避免阻塞启动
   * 
   * 错误处理：
   * - 初始化失败会记录日志
   * - 关键模块失败可能影响应用功能
   * - 非关键模块失败应用仍可运行
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
    logger.info(`${LOG_TAG.ENTRY_ABILITY}应用启动，开始初始化流程`)
    
    // 阶段 1：基础模块初始化
    appInit.initPhase1_BaseModules(this.context).then(success => {
      if (success) {
        logger.info(`${LOG_TAG.ENTRY_ABILITY}阶段 1 初始化成功`)
      } else {
        logger.error(`${LOG_TAG.ENTRY_ABILITY}阶段 1 初始化失败，应用可能无法正常运行`)
      }
    }).catch((error: Error) => {
      logger.error(`${LOG_TAG.ENTRY_ABILITY}阶段 1 初始化异常: ${JSON.stringify(error)}`)
    })
  }

  /**
   * 应用销毁生命周期回调
   * 
   * 在应用退出时调用，进行资源清理
   * 
   * @remarks
   * 清理内容：
   * - 释放数据库连接
   * - 取消事件监听
   * - 清理临时数据
   */
  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
    logger.info(`${LOG_TAG.ENTRY_ABILITY}应用销毁`)
  }

  /**
   * 窗口阶段创建生命周期回调
   * 
   * 在窗口创建后调用，是初始化的第二和第三阶段
   * 
   * @param windowStage - 窗口舞台对象，用于管理窗口和加载页面
   * 
   * @remarks
   * 初始化内容：
   * - 阶段 2：窗口相关初始化（颜色模式管理器等）
   * - AppStorageV2 初始化（窗口宽度）
   * - 页面加载（StartPage）
   * - 阶段 3：UI 依赖初始化（Markdown 配置等）
   * 
   * AppStorageV2 初始化时机：
   * - 窗口创建后，页面加载前
   * - 必须在访问 AppStorageV2 之前完成
   * 
   * 页面加载策略：
   * - 首先加载启动页（StartPage）
   * - 启动页会自动跳转到主页（Index）
   * - 使用路由动画提升用户体验
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');
    logger.info(`${LOG_TAG.ENTRY_ABILITY}窗口创建，开始窗口相关初始化`)
    
    // 阶段 2：窗口相关模块初始化
    const phase2Success = appInit.initPhase2_WindowRelated(this.context.getApplicationContext())
    if (phase2Success) {
      logger.info(`${LOG_TAG.ENTRY_ABILITY}阶段 2 初始化成功`)
    } else {
      logger.warn(`${LOG_TAG.ENTRY_ABILITY}阶段 2 初始化失败，部分功能可能受影响`)
    }
    
    // 初始化 AppStorageV2：存储窗口宽度
    window.getLastWindow(this.context).then((win) => {
      const winWidth = win.getWindowProperties().windowRect.width
      AppStorageV2.connect(WinWidth, APP_STORAGE_KEYS.WINDOW_WIDTH, () => new WinWidth(winWidth))
      logger.info(`${LOG_TAG.ENTRY_ABILITY}窗口宽度已存储到 AppStorageV2: ${winWidth}px`)
    }).catch((error: Error) => {
      logger.error(`${LOG_TAG.ENTRY_ABILITY}获取窗口宽度失败: ${JSON.stringify(error)}`)
    })
    
    // 加载启动页面
    windowStage.loadContent('pages/StartPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        logger.error(`${LOG_TAG.ENTRY_ABILITY}页面加载失败: ${JSON.stringify(err)}`)
        return;
      }
      
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
      logger.info(`${LOG_TAG.ENTRY_ABILITY}启动页加载成功`)
      
      // 阶段 3：UI 依赖模块初始化
      const phase3Success = appInit.initPhase3_UIDependent()
      if (phase3Success) {
        logger.info(`${LOG_TAG.ENTRY_ABILITY}阶段 3 初始化成功`)
      } else {
        logger.warn(`${LOG_TAG.ENTRY_ABILITY}阶段 3 初始化失败，部分功能可能受影响`)
      }
      
      // 检查完整初始化状态
      if (appInit.isFullyInitialized()) {
        logger.info(`${LOG_TAG.ENTRY_ABILITY}应用完全初始化成功，所有功能可用`)
      } else {
        logger.warn(`${LOG_TAG.ENTRY_ABILITY}应用初始化不完整，部分功能可能受限`)
        const status = appInit.getInitStatus()
        logger.warn(`${LOG_TAG.ENTRY_ABILITY}初始化状态: ${JSON.stringify(status)}`)
      }
    });
  }

  /**
   * 窗口阶段销毁生命周期回调
   * 
   * 在窗口销毁时调用，释放 UI 相关资源
   * 
   * @remarks
   * 清理内容：
   * - 释放 UI 资源
   * - 取消窗口监听
   * - 清理临时 UI 状态
   */
  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
    logger.info(`${LOG_TAG.ENTRY_ABILITY}窗口销毁`)
  }

  /**
   * 应用进入前台生命周期回调
   * 
   * 当应用从后台切换到前台时调用
   * 
   * @remarks
   * 可能的操作：
   * - 刷新数据：检查是否有新内容
   * - 恢复状态：恢复用户操作状态
   * - 重新连接：重新建立网络连接
   */
  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
    logger.info(`${LOG_TAG.ENTRY_ABILITY}应用进入前台`)
  }

  /**
   * 应用进入后台生命周期回调
   * 
   * 当应用从前台切换到后台时调用
   * 
   * @remarks
   * 数据保存：
   * - 自动保存用户配置到持久化存储
   * - 确保用户数据不丢失
   * - 为下次启动做准备
   * 
   * 保存内容：
   * - 用户字体大小设置
   * - 用户颜色模式偏好
   * - 其他用户配置项
   * 
   * 执行时机：
   * - 用户按Home键退出
   * - 切换到其他应用
   * - 系统内存不足时被挂起
   */
  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
    logger.info(`${LOG_TAG.ENTRY_ABILITY}应用进入后台，开始保存用户数据`)
    
    // 同步用户配置到持久化存储
    const syncSuccess = userConfigManager.syncDataToPreference()
    if (syncSuccess) {
      logger.info(`${LOG_TAG.ENTRY_ABILITY}用户配置保存成功`)
    } else {
      logger.error(`${LOG_TAG.ENTRY_ABILITY}用户配置保存失败，设置可能丢失`)
    }
  }
}
