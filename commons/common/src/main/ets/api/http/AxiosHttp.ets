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
import axios, { AxiosError, AxiosRequestConfig, AxiosResponse } from "@ohos/axios"
import { logger } from "../../utils"
import { AppStorageV2, promptAction } from "@kit.ArkUI"
import { SERVE_BASE_ADDRESS } from "../../modules/constants"
import { GetUIContext } from "../../modules/context/GetUIContext"
import { LOG_TAG } from '../../modules/enums';

/**
 * axios请求实例
 * 配置基地址和请求超时时间
 */
export const axiosInstance = axios.create({
  baseURL: SERVE_BASE_ADDRESS,
  timeout: 200000
})

// logger.debug('请求获取UIContext')


/**
 * 设置响应拦截器拦截器
 * interceptors:    拦截器
 * response:        响应
 * 由这个axiosInstance实例发送到请求的响应都会经过它再返回
 */
// 响应拦截器
axiosInstance.interceptors.response.use((res: AxiosResponse) => {

  if (res.status === 200) {
    logger.warn(LOG_TAG.AXIOS_HTTP + 'Req Success' + JSON.stringify(res.data))
    return res.data
  }
  logger.error(LOG_TAG.AXIOS_HTTP + 'ReqCode Error' + JSON.stringify(res.data))
  promptAction.showToast({ message: 'ReqCode Error' + JSON.stringify(res.data)})
  return Promise.reject(res.data)
}, (err: AxiosError) => {
  logger.error(LOG_TAG.AXIOS_HTTP + 'AxiosReq Error' + err.message + ' URL = ' + err.config?.url)
  promptAction.showToast({ message: 'AxiosReq Error' + err.message })
  return Promise.reject(err)
})

class AxiosHttp {
  /**
   * Axios包装过的请求函数
   * @param config 网络请求配置项
   * <res:响应数据类型
   * req:请求体参数类型 - get不需要传>
   */
  request<res, req = Object>(config: AxiosRequestConfig<req>) {
    logger.debug(LOG_TAG.AXIOS_HTTP + '进入AxiosHttp.request' + ` URL = ${config.url}`)
    return axiosInstance<null, res, req>(config)
  }
}

/**
 * 包装后的axios请求，添加了拦截器直接选取res.data中的字段
 */
export const axiosHttp = new AxiosHttp()