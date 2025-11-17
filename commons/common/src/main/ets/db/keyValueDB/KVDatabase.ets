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
import { distributedKVStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { logger } from "../../utils/logger/logger";
import { common } from '@kit.AbilityKit';
import { LOG_TAG } from '../../modules/enums';

/**
 * 键值型数据库管理类
 * 
 * 提供 KV（Key-Value）数据库的初始化、获取和管理功能
 * 
 * @remarks
 * KV 数据库特点：
 * - 存储格式：键值对形式，类似于 Map 数据结构
 * - 数据类型：支持字符串、数字、布尔、数组、对象等
 * - 持久化：数据保存在本地，应用重启后仍然存在
 * - 分布式：支持多设备数据同步（本应用未启用）
 * 
 * 使用场景：
 * - 缓存服务器数据：减少网络请求，提升响应速度
 * - 离线访问：用户无网络时可浏览缓存的内容
 * - 临时数据：不需要复杂查询的简单数据存储
 * 
 * 与 PreferenceDB 的区别：
 * - KVDatabase：适合存储较大的数据集合（如新闻列表）
 * - PreferenceDB：适合存储简单的配置项（如用户设置）
 * 
 * 初始化流程：
 * 1. 应用启动时调用 init() 创建 KVManager
 * 2. 使用 getKVStoreById() 获取具体的数据库实例
 * 3. 通过数据库实例进行增删改查操作
 * 
 * @example
 * ```typescript
 * // 1. 初始化数据库
 * kvDatabase.init(this.context)
 * 
 * // 2. 获取数据库实例
 * const store = await kvDatabase.getKVStoreById('myDatabase')
 * 
 * // 3. 存储数据
 * await store.put('myKey', JSON.stringify(myData))
 * 
 * // 4. 读取数据
 * const value = await store.get('myKey')
 * const data = JSON.parse(value as string)
 * ```
 * 
 * @see NewsManager 新闻管理器中的实际使用示例
 */
export class KVDatabase {
  /**
   * 数据库管理对象
   * 
   * KVManager 是 HarmonyOS 提供的 KV 数据库管理器，负责：
   * - 创建和管理多个 KV 数据库实例
   * - 监听数据库服务状态
   * - 处理数据库的生命周期
   * 
   * @remarks
   * - 初始值为 undefined，需通过 init() 方法初始化
   * - 应用启动时必须先初始化，否则无法使用数据库功能
   * - 整个应用生命周期中只需初始化一次
   */
  kvManager: distributedKVStore.KVManager | undefined = undefined;
  
  /**
   * 应用包名标识
   * 
   * 用于标识数据库所属的应用，确保数据隔离
   * 
   * @remarks
   * - 必须与应用的 bundleName 保持一致
   * - 不同应用的数据库相互隔离
   * - 修改此值会导致无法访问之前的数据库
   */
  appId: string = 'com.xbxyftx.NowInOpenHarmony';

  /**
   * 初始化数据库管理器
   * 
   * 创建 KVManager 实例，是使用 KV 数据库的前提条件
   * 
   * @param context - UIAbility 上下文对象，用于访问应用环境
   * @returns true: 初始化成功；false: 初始化失败
   * 
   * @remarks
   * 调用时机：
   * - 应用启动时，在 EntryAbility 的 onCreate() 中调用
   * - 整个应用生命周期只需调用一次
   * - 必须在使用任何数据库功能之前调用
   * 
   * 失败原因：
   * - context 对象无效
   * - 系统资源不足
   * - bundleName 配置错误
   * 
   * @example
   * ```typescript
   * // 在 EntryAbility 中初始化
   * onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
   *   const success = kvDatabase.init(this.context)
   *   if (success) {
   *     logger.info('KV 数据库初始化成功')
   *   }
   * }
   * ```
   */
  init(context: common.UIAbilityContext): boolean {
    const kvManagerConfig: distributedKVStore.KVManagerConfig = {
      context: context,
      bundleName: this.appId
    };
    try {
      // 创建KVManager实例
      this.kvManager = distributedKVStore.createKVManager(kvManagerConfig);
      console.info(LOG_TAG.KV_DATABASE + 'Succeeded in creating KVManager.');
      // 继续创建获取数据库
      if (this.kvManager !== undefined) {
        logger.info(LOG_TAG.KV_DATABASE+'数据库管理对象创建成功。')
        return true
      }
      logger.error(LOG_TAG.KV_DATABASE + '数据库管理对象创建失败')
      return false
    } catch (e) {
      let error = e as BusinessError;
      logger.error(LOG_TAG.KV_DATABASE + `Failed to create KVManager. Code:${error.code},message:${error.message}`);
      return false
    }
  }

  /**
   * 通过 ID 获取数据库实例对象
   * 
   * 根据指定的数据库 ID 获取或创建一个 KV 数据库实例
   * 
   * @param storeId - 数据库实例的唯一标识符
   * @returns Promise<SingleKVStore | null> - 数据库实例对象，失败时返回 null
   * 
   * @remarks
   * 前置条件：
   * - 必须先调用 init() 方法初始化 KVManager
   * - 如果 kvManager 未初始化，将直接返回 null
   * 
   * 数据库配置：
   * - createIfMissing: true - 数据库不存在时自动创建
   * - securityLevel: S1 - 安全级别（S1 为最低级别，适合公开数据）
   * - kvStoreType: SINGLE_VERSION - 单版本数据库（不支持分布式同步）
   * 
   * 监听机制：
   * - 自动监听数据库服务状态变化
   * - 当数据库服务异常时会记录警告日志
   * 
   * 使用建议：
   * - 建议为不同类型的数据创建不同的数据库实例
   * - 本应用中使用 APP_KV_DB 常量作为统一的 storeId
   * - 数据库实例可以被缓存复用，无需每次都重新获取
   * 
   * @example
   * ```typescript
   * // 获取数据库实例
   * const store = await kvDatabase.getKVStoreById(APP_KV_DB)
   * if (store) {
   *   // 存储数据
   *   await store.put(KV_DB_KEYS.NEWS_ARTICLE_LIST, JSON.stringify(newsList))
   *   
   *   // 读取数据
   *   const data = await store.get(KV_DB_KEYS.NEWS_ARTICLE_LIST)
   *   const articles = JSON.parse(data as string)
   * }
   * ```
   * 
   * @throws 不会抛出异常，所有错误都会被捕获并记录日志
   */
  async getKVStoreById(storeId:string):Promise<distributedKVStore.SingleKVStore|null>{
    if (this.kvManager) {
      try {
        const options:distributedKVStore.Options = {
          createIfMissing: true,
          securityLevel: distributedKVStore.SecurityLevel.S1,
          kvStoreType:distributedKVStore.KVStoreType.SINGLE_VERSION
        }
        const kVStore:distributedKVStore.SingleKVStore = await this.kvManager.getKVStore(storeId,options)
        if (kVStore) {
          logger.info(`${LOG_TAG.KV_DATABASE}成功获取storeId:${storeId}数据库实例对象`)
          this.kvManager.on('distributedDataServiceDie',()=>{
            logger.warn(`${LOG_TAG.KV_DATABASE}数据库服务订阅发生变更`)
          })
          return kVStore
        }
      }catch (e){
        let err = e as BusinessError
        logger.error(`${LOG_TAG.KV_DATABASE}获取KV数据库实例对象异常，异常信息: ${err.message}`)
      }
    }
    return null
  }


}

/**
 * KV 数据库单例对象
 * 
 * 全局唯一的 KVDatabase 实例，整个应用共享使用
 * 
 * @remarks
 * 使用单例模式的优势：
 * - 确保整个应用只有一个数据库管理器实例
 * - 避免重复初始化，节省系统资源
 * - 便于全局访问和状态管理
 * 
 * @example
 * ```typescript
 * import { kvDatabase } from 'common'
 * 
 * // 初始化（仅在应用启动时调用一次）
 * kvDatabase.init(this.context)
 * 
 * // 在任何地方使用
 * const store = await kvDatabase.getKVStoreById(APP_KV_DB)
 * ```
 */
export const kvDatabase: KVDatabase = new KVDatabase()