import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("ElecPrice es una aplicación iOS que muestra los precios de electricidad en tiempo real para España.")
                        .font(.body)
                        .padding(.bottom)
                    
                    Group {
                        Text("Características")
                            .font(.headline)
                        
                        Text("• Muestra los precios de electricidad por hora\n• Indica el precio actual, más bajo y más alto del día\n• Visualiza los precios en un gráfico de líneas\n• Utiliza datos en tiempo real cuando es posible\n• Funciona con datos aproximados cuando no hay conexión")
                    }
                    
                    Group {
                        Text("Fuentes de datos")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("La aplicación obtiene datos de tarifaluzhora.es y la API de Red Eléctrica de España.")
                    }
                    
                    Group {
                        Text("Información")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("Versión: 1.1.0\nDesarrollado por: ElecPrice Team")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Acerca de")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AboutView()
} 