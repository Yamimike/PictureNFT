struct UID(u64);

struct Picture {
    id: UID,
    uri: String,
    price: u64,
    owner: String,
    for_sale: bool,
}

struct Gallery {
    pictures: Vec<Picture>,
}

struct TxContext {
    sender: String,
    value: u64,
}

enum GalleryError {
    ENotOwner,
    ENotEnoughBalance,
    EPictureNotFound,
    EOwnedBySomeoneElse,
    EListedForSale,
    ENotListedForSale
}

impl Gallery {
    pub fn buy_picture(&mut self, picture_id: UID, ctx: &mut TxContext) -> Result<(), GalleryError> {
        let picture = self.get_picture(picture_id)?;
        let price = picture.price;
        if ctx.value < price {
            return Err(GalleryError::ENotEnoughBalance);
        }
        let picture_owner = picture.owner.clone();
        picture.owner = tx_context::sender(ctx);
        ctx.value -= price;
        table::borrow_mut(&mut self.pictures, picture_id).for_sale = false;
        table::borrow_mut(self.buyers, tx_context::sender(ctx))?.push(picture_id);
        table::borrow_mut(self.sellers, picture_owner)?.remove(picture_id);
        Ok(())
    }

    pub fn add_picture(&mut self, uri: String, price: u64, ctx: &mut TxContext) -> Result<(), GalleryError> {
        let id = UID(rand::random());
        let picture = Picture {
            id: id,
            uri: uri,
            price: price,
            owner: tx_context::sender(ctx),
            for_sale: false,
        };
        self.pictures.push(picture);
        table::borrow_mut(self.sellers, tx_context::sender(ctx))?.insert(id);
        Ok(())
    }

    pub fn update_picture(
        &mut self,
        picture_id: UID,
        new_uri: String,
        new_price: u64,
        ctx: &mut TxContext,
    ) -> Result<(), GalleryError> {
        let picture = table::borrow_mut(&mut self.pictures, picture_id);
        if picture.owner != tx_context::sender(ctx) {
            return Err(GalleryError::ENotOwner);
        }
        if picture.for_sale {
            return Err(GalleryError::EListedForSale);
        }
        picture.uri = new_uri;
        picture.price = new_price;
        Ok(())
    }

    pub fn list_picture(&mut self, picture_id: UID, ctx: &mut TxContext) -> Result<(), GalleryError> {
        let picture = table::borrow_mut(&mut self.pictures, picture_id);
        if picture.owner != tx_context::sender(ctx) {
            return Err(GalleryError::ENotOwner);
        }
        if picture.for_sale {
            return Err(GalleryError::EListedForSale);
        }
        picture.for_sale = true;
        table::borrow_mut(self.sellers, tx_context::sender(ctx))?.remove(picture_id);
        table::borrow_mut(self.buyers, tx_context::sender(ctx))?.remove(picture_id);
        table::borrow_mut(self.for_sale, picture.price)?.insert(picture_id);
        Ok(())
    }

    fn get_picture(&self, picture_id: UID) -> Result<Picture, GalleryError> {
        let index = self
            .pictures
            .iter()
            .position(|picture| picture.id == picture_id)
            .ok_or(GalleryError::EPictureNotFound)?;
        Ok(self.pictures[index].clone())
    }
}

fn main() {
    let mut gallery = Gallery { pictures: vec![] };
    let mut tx_ctx = TxContext {
        sender: String::new(),
        value: 0,
    };
    let mut buyers = table::new();
    let mut sellers = table::new();
    let mut for_sale = table::new();

    table::insert(&mut buyers, String::new(), Vec::new());
    table::insert(&mut sellers, String::new(), HashSet::new());
    table::insert(&mut for_sale, 0, HashSet::new());

    gallery.add_picture("https://picsum.photos/200".to_string(), 100, &mut tx_ctx).unwrap();
    gallery.list_picture(UID(0), &mut tx_ctx).unwrap();

    println!("{:#?}", gallery);
}
 
