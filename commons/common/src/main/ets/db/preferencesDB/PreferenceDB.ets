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
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { logger } from '../../utils';
import { promptAction } from '@kit.ArkUI';
import { LOG_TAG } from '../../modules/enums';

/**
 * 用户偏好设置数据持久化管理类
 * 
 * 提供轻量级键值对数据的持久化存储，适合保存应用配置和用户设置
 * 
 * @remarks
 * Preferences 数据库特点：
 * - 轻量级：适合存储简单的配置数据
 * - 键值对：以 key-value 形式存储
 * - 持久化：数据保存在本地，应用重启后保持
 * - 同步操作：提供同步 API，读写速度快
 * - 数据监听：支持监听数据变化
 * 
 * 与 KVDatabase 的区别：
 * - PreferenceDB: 适合小量配置数据（<100条），如用户设置
 * - KVDatabase: 适合大量业务数据，如新闻列表、图片缓存
 * 
 * 本应用中的使用：
 * - 存储用户字体大小设置（FONT_SIZE）
 * - 存储用户颜色模式偏好（COLOR_MODE）
 * - 其他用户个性化配置
 * 
 * 数据流转：
 * 1. 用户修改设置 → UI 更新
 * 2. UI 更新 → AppStorageV2 状态更新
 * 3. 状态更新 → PreferenceDB 持久化
 * 4. 应用重启 → PreferenceDB 读取 → 恢复 AppStorageV2 状态
 * 
 * @example
 * ```typescript
 * // 1. 初始化
 * preferenceDB.init(this.context)
 * 
 * // 2. 存储数据
 * preferenceDB.pushData(PreferenceEnum.FONT_SIZE, 18)
 * 
 * // 3. 检查数据是否存在
 * if (preferenceDB.hasData(PreferenceEnum.FONT_SIZE)) {
 *   // 4. 读取数据
 *   const fontSize = preferenceDB.getData<number>(PreferenceEnum.FONT_SIZE)
 * }
 * 
 * // 5. 删除数据
 * preferenceDB.deleteData(PreferenceEnum.FONT_SIZE)
 * ```
 * 
 * @see UserConfigManager 用户配置管理器中的实际使用示例
 * @see PreferenceEnum 偏好设置枚举，定义所有可用的配置键
 */
class PreferenceDB {
  /**
   * 偏好设置数据库实例
   * 
   * HarmonyOS 提供的 Preferences 对象，用于实际的数据读写操作
   * 
   * @remarks
   * - 初始值为 null，需通过 init() 方法初始化
   * - 初始化后可进行数据的增删改查
   * - 支持监听数据变化事件
   * 
   * @private
   */
  private dataPreference: preferences.Preferences | null = null;

  /**
   * 初始化偏好设置数据库
   * 
   * 创建或获取 Preferences 实例，并注册数据变化监听
   * 
   * @param context - 应用上下文对象，用于访问应用环境
   * @returns true: 初始化成功；false: 初始化失败
   * 
   * @remarks
   * 调用时机：
   * - 应用启动时，在需要使用偏好设置之前调用
   * - 通常在 EntryAbility 的 onCreate() 中调用
   * - 整个应用生命周期只需调用一次
   * 
   * 数据库名称：
   * - 名称固定为 'jyt'
   * - 不同的应用或模块可以创建多个 Preferences 实例
   * 
   * 监听机制：
   * - 自动监听所有键的数据变化
   * - 数据变化时会记录警告日志
   * - 便于调试和追踪配置变更
   * 
   * @example
   * ```typescript
   * // 在 EntryAbility 中初始化
   * onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
   *   if (preferenceDB.init(this.context)) {
   *     logger.info('偏好设置数据库初始化成功')
   *   }
   * }
   * ```
   */
  init(context: common.BaseContext): boolean {
    const option: preferences.Options = { name: 'jyt' };
    this.dataPreference = preferences.getPreferencesSync(context, option);
    this.dataPreference.on("change", (key: string) => {
      logger.warn(`${LOG_TAG.PREFERENCE_DB}The key ${key} changed`);
    });
    if (this.dataPreference) {
      return true
    }
    return false
  }

  /**
   * 释放资源，取消数据变化监听
   * 
   * 在不再需要偏好设置时调用，释放系统资源
   * 
   * @remarks
   * 调用时机：
   * - 应用退出时
   * - 不再需要监听数据变化时
   * 
   * 注意事项：
   * - 调用后仍可正常使用数据库
   * - 仅取消监听，不影响数据读写
   * - 通常情况下可以不调用（系统会自动清理）
   */
  release(): void {
    if (this.dataPreference) {
      this.dataPreference.off("change", (key: string) => {
        logger.warn(`${LOG_TAG.PREFERENCE_DB}UnSubscribe the key ${key}`);
      });
    }
  }

  /**
   * 检查指定键的数据是否存在
   * 
   * @param key - 数据键名，建议使用 PreferenceEnum 中的枚举值
   * @returns true: 数据存在；false: 数据不存在或数据库未初始化
   * 
   * @remarks
   * 使用场景：
   * - 首次启动检测：判断用户是否有保存的配置
   * - 数据迁移：检查旧版本数据是否存在
   * - 条件逻辑：根据配置是否存在执行不同操作
   * 
   * @example
   * ```typescript
   * if (!preferenceDB.hasData(PreferenceEnum.FONT_SIZE)) {
   *   // 首次启动，设置默认字体大小
   *   preferenceDB.pushData(PreferenceEnum.FONT_SIZE, DEFAULT_FONT_SIZE)
   * }
   * ```
   */
  hasData(key: string): boolean {
    if (this.dataPreference) {
      const dataExist: boolean = this.dataPreference.hasSync(key);
      logger.info(`${LOG_TAG.PREFERENCE_DB}Has ${key} data: ${dataExist}`);
      return dataExist;
    }
    return false;
  }

  /**
   * 存储数据到偏好设置
   * 
   * 将键值对数据持久化到本地存储
   * 
   * @param key - 数据键名，建议使用 PreferenceEnum 中的枚举值
   * @param value - 要存储的数据，支持 string、number、boolean、Array、Object
   * 
   * @remarks
   * 数据类型：
   * - 基本类型：string、number、boolean 可直接存储
   * - 复杂类型：Object、Array 需要先序列化（通常不建议）
   * - 建议：复杂数据使用 KVDatabase 存储
   * 
   * 持久化机制：
   * - 调用 putSync() 后数据暂存在内存
   * - 调用 flush() 强制写入磁盘
   * - 确保数据不会因应用崩溃而丢失
   * 
   * 注意事项：
   * - 数据会覆盖同名键的旧值
   * - 存储操作是同步的，大量数据会阻塞主线程
   * - 建议只存储小量配置数据
   * 
   * @example
   * ```typescript
   * // 存储简单类型
   * preferenceDB.pushData(PreferenceEnum.FONT_SIZE, 18)
   * preferenceDB.pushData(PreferenceEnum.COLOR_MODE, 1)
   * 
   * // 不建议：存储复杂对象（应使用 KVDatabase）
   * // preferenceDB.pushData('userInfo', { name: 'John', age: 25 })
   * ```
   */
  pushData(key: string, value: Object): void {
    if (this.dataPreference) {
      logger.warn(`${LOG_TAG.PREFERENCE_DB}push data: key=${key},value=${value}`)
      this.dataPreference.putSync(key, value);
      this.dataPreference.flush();
    }
  }

  /**
   * 删除指定键的数据
   * 
   * 从偏好设置中永久删除指定键及其对应的值
   * 
   * @param key - 要删除的数据键名
   * 
   * @remarks
   * 使用场景：
   * - 清除用户配置：重置为默认状态
   * - 数据迁移：删除旧版本的配置项
   * - 隐私保护：用户注销时清除个人设置
   * 
   * 注意事项：
   * - 删除操作不可恢复
   * - 删除不存在的键不会报错
   * - 删除后 hasData() 会返回 false
   * 
   * @example
   * ```typescript
   * // 重置用户设置
   * preferenceDB.deleteData(PreferenceEnum.FONT_SIZE)
   * preferenceDB.deleteData(PreferenceEnum.COLOR_MODE)
   * ```
   */
  deleteData(key: string): void {
    if (this.dataPreference) {
      this.dataPreference.deleteSync(key);
      logger.warn(`${LOG_TAG.PREFERENCE_DB}Delete data ${key}`);
    }
  }

  /**
   * 获取指定键的数据
   * 
   * 从偏好设置中读取数据，支持泛型类型转换
   * 
   * @template T - 返回值的类型，建议明确指定以获得类型安全
   * @param key - 数据键名，建议使用 PreferenceEnum 中的枚举值
   * @returns T | null - 读取到的数据，失败时返回 null
   * 
   * @remarks
   * 类型转换：
   * - 使用泛型指定返回类型：getData<number>()
   * - 如果实际类型与指定类型不符，可能导致运行时错误
   * - 建议：明确知道数据类型时再进行转换
   * 
   * 默认值：
   * - 键不存在时返回字符串 'default'
   * - 然后将其转换为 T 类型（可能不安全）
   * - 建议：先用 hasData() 检查再读取
   * 
   * 异常处理：
   * - 捕获所有异常，避免应用崩溃
   * - 异常时显示 Toast 提示用户
   * - 同时记录错误日志便于调试
   * 
   * @example
   * ```typescript
   * // 推荐：先检查再读取
   * if (preferenceDB.hasData(PreferenceEnum.FONT_SIZE)) {
   *   const fontSize = preferenceDB.getData<number>(PreferenceEnum.FONT_SIZE)
   *   console.log(`用户字体大小: ${fontSize}`)
   * }
   * 
   * // 读取不同类型的数据
   * const colorMode = preferenceDB.getData<0 | 1 | 2>(PreferenceEnum.COLOR_MODE)
   * ```
   * 
   * @throws 不会抛出异常，所有错误都会被捕获并通过 Toast 和日志提示
   */
  getData<T>(key: string): T | null {
    try {
      if (this.dataPreference) {
        const obj: preferences.ValueType = this.dataPreference.getSync(key, 'default');
        logger.warn(`${LOG_TAG.PREFERENCE_DB}Get data ${key}: ${JSON.stringify(obj)}`);
        return obj as T;
      }
      return null;
    }catch (e){
      promptAction.openToast({message:`${LOG_TAG.PREFERENCE_DB}获取数据异常，异常信息为${JSON.stringify(e)}`})
      logger.error(`${LOG_TAG.PREFERENCE_DB}获取数据异常，异常信息为${JSON.stringify(e)}`)
    }
    return null
  }
}

/**
 * 偏好设置数据库单例对象
 * 
 * 全局唯一的 PreferenceDB 实例，整个应用共享使用
 * 
 * @remarks
 * 单例模式优势：
 * - 确保应用只有一个偏好设置管理器
 * - 避免重复初始化和资源浪费
 * - 便于在不同模块间共享配置数据
 * 
 * 使用流程：
 * 1. 应用启动时调用 init() 初始化
 * 2. 在任何地方通过 preferenceDB 访问
 * 3. 无需手动创建实例
 * 
 * @example
 * ```typescript
 * import { preferenceDB, PreferenceEnum } from 'common'
 * 
 * // 应用启动时初始化
 * preferenceDB.init(this.context)
 * 
 * // 在任何组件或管理器中使用
 * preferenceDB.pushData(PreferenceEnum.FONT_SIZE, 18)
 * const fontSize = preferenceDB.getData<number>(PreferenceEnum.FONT_SIZE)
 * ```
 */
export const preferenceDB: PreferenceDB = new PreferenceDB();
