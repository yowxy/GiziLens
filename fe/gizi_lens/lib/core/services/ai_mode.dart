const useApiAi = bool.fromEnvironment('USE_API_AI', defaultValue: true);

const aiProviderName = useApiAi ? 'sumopod' : 'onnx';
const aiModelName = useApiAi ? 'deepseek-v4-flash' : 'best.onnx';
