import SwiftUI

struct AlbumsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Album.entity(), sortDescriptors: [])
    var albums: FetchedResults<Album>

    var body: some View {
        NavigationStack {
            List {
                ForEach(albums) { album in
                    NavigationLink(destination: AlbumDetailView(albumID: album.objectID)) {
                        Text(album.name ?? "Unnamed Album")
                    }
                }
                .onDelete(perform: deleteAlbum)
            }
            .navigationTitle("Albums")
            .toolbar {
                EditButton()
            }
        }
    }

    func deleteAlbum(at offsets: IndexSet) {
        for index in offsets {
            let albumToDelete = albums[index]
            viewContext.delete(albumToDelete)
        }
        try? viewContext.save()
    }
}
