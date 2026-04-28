import SwiftUI

struct PopoverExample<Content: View>: View {
    var contentView: (@escaping () -> Void) -> Content
    @State private var showPopover = false
    
    var body: some View {
        AttachmentButtonView(onTap: {showPopover = true})
            .popover(isPresented: $showPopover,content: {
                contentView{
                    showPopover = false 
                }
            })
        
    }
}
