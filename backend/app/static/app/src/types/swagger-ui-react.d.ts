declare module 'swagger-ui-react' {
  import { Component } from 'react'

  export interface SwaggerUIProps {
    spec?: any
    url?: string
    deepLinking?: boolean
    displayRequestDuration?: boolean
    filter?: boolean | string
    showExtensions?: boolean
    showCommonExtensions?: boolean
    tryItOutEnabled?: boolean
    docExpansion?: 'list' | 'full' | 'none'
    syntaxHighlight?: {
      activate?: boolean
      theme?: string
    }
    supportedSubmitMethods?: string[]
  }

  export default class SwaggerUI extends Component<SwaggerUIProps> {}
}

