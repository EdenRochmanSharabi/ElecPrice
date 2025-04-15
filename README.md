# ElecPrice - Precios de Electricidad para Sanlúcar

Una aplicación iOS para consultar los precios de electricidad en tiempo real para Sanlúcar.

## Características

- Muestra los precios de electricidad por hora
- Indica el precio actual, más bajo y más alto del día
- Visualiza los precios en un gráfico de líneas
- Utiliza datos en tiempo real cuando es posible
- Funciona con datos aproximados cuando no hay conexión

## Configuración del proyecto

### Añadir SwiftSoup para web scraping

La aplicación utiliza SwiftSoup para extraer datos de precios de electricidad de sitios web públicos. Para añadir SwiftSoup a tu proyecto:

1. Abre el proyecto en Xcode
2. Selecciona File > Add Packages...
3. Pega la URL: `https://github.com/scinfu/SwiftSoup.git`
4. Haz clic en "Add Package"
5. Asegúrate de que el paquete se añade a tu target principal

### Configuración de la API (opcional)

Si tienes una clave de API para la API de REE (Red Eléctrica de España), puedes configurarla en el archivo `ElectricityService.swift`.

## Fuentes de datos

La aplicación intenta obtener datos de las siguientes fuentes, en orden de prioridad:

1. **Web scraping** - Extrae datos de tarifaluzhora.es
2. **API de REE** - Utiliza la API oficial si está disponible
3. **Datos estimados** - Genera datos aproximados basados en patrones típicos

## Desarrollo

El proyecto está estructurado en:

- **Models**: Modelos de datos para los precios de electricidad
- **Views**: Interfaz de usuario para visualizar los precios
- **Services**: Servicios para obtener y procesar datos

## Licencia

© 2025 - Todos los derechos reservados 