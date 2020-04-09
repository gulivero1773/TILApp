import Vapor
import Leaf

struct WebsiteController: RouteCollection {
  func boot(router: Router) throws {
    router.get(use: indexHandler)
    router.get("acronyms", Acronym.parameter, use: acronymHandler)
    router.get("users", User.parameter, use: userHandler)
    router.get("users", use: allUsersHandler)
    router.get("categories", use: allCategoriesHandler)
    router.get("categories", Category.parameter, use: categoryHandler)
    router.get("acronyms", "create", use: createAcronymHandler)
    router.post(Acronym.self, at: "acronyms", "create", use: createAcronymPostHandler)
    router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
    router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
    router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
  }

  func indexHandler(_ req: Request) throws -> Future<View> {
    return Acronym.query(on: req).all().flatMap(to: View.self) { acronyms in
      let context = IndexContext(title: "Home page", acronyms: acronyms)
      return try req.view().render("index", context)
    }
  }

  func acronymHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
      return acronym.user.get(on: req).flatMap(to: View.self) { user in
        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
        return try req.view().render("acronym", context)
      }
    }
  }

  func userHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(User.self).flatMap(to: View.self) { user in
        return try user.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
            let context = UserContext(title: user.name, user: user, acronyms: acronyms)
            return try req.view().render("user", context)
        }
    }
  }

  func allUsersHandler(_ req: Request) throws -> Future<View> {
    return User.query(on: req).all().flatMap(to: View.self) { users in
        let context = AllUsersContext(title: "All Users", users: users)
        return try req.view().render("allUsers", context)
    }
  }
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
      // 1
      let categories = Category.query(on: req).all()
      let context = AllCategoriesContext(categories: categories)
      // 2
      return try req.view().render("allCategories", context)
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
      // 1
      return try req.parameters.next(Category.self)
        .flatMap(to: View.self) { category in
          // 2
          let acronyms = try category.acronyms.query(on: req).all()
          // 3
          let context = CategoryContext(
            title: category.name,
            category: category,
            acronyms: acronyms)
          // 4
          return try req.view().render("category", context)
      }
    }
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> {
      // 1
      let context = CreateAcronymContext(
        users: User.query(on: req).all())
      // 2
      return try req.view().render("createAcronym", context)
    }
    
    func createAcronymPostHandler(_ req: Request, acronym: Acronym) throws -> Future<Response> {
      // 2
      return acronym.save(on: req)
        .map(to: Response.self) { acronym in
          // 3
          guard let id = acronym.id else {
            throw Abort(.internalServerError)
          }
          // 4
          return req.redirect(to: "/acronyms/\(id)")
      }
    }
    
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
      // 1
      return try req.parameters.next(Acronym.self)
        .flatMap(to: View.self) { acronym in
          // 2
          let context = EditAcronymContext(
            acronym: acronym,
            users: User.query(on: req).all())
          // 3
          return try req.view().render("createAcronym", context)
      }
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
      // 1
      return try flatMap(to: Response.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, data in
        // 2
        acronym.short = data.short
        acronym.long = data.long
        acronym.userID = data.userID
        
        guard let id = acronym.id else {
          throw Abort(.internalServerError)
        }
        let redirect = req.redirect(to: "/acronyms/\(id)")
        // 4
        return acronym.save(on: req).transform(to: redirect)
      }
    }
    
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
      return try req.parameters.next(Acronym.self).delete(on: req)
        .transform(to: req.redirect(to: "/"))
    }
    
}

struct IndexContext: Encodable {
  let title: String
  let acronyms: [Acronym]
}

struct AcronymContext: Encodable {
  let title: String
  let acronym: Acronym
  let user: User
}

struct UserContext: Encodable {
  let title: String
  let user: User
  let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
  let title: String
  let users: [User]
}

struct AllCategoriesContext: Encodable {
  // 1
  let title = "All Categories"
  // 2
  let categories: Future<[Category]>
}

struct CategoryContext: Encodable {
  let title: String
  let category: Category
  let acronyms: Future<[Acronym]>
}

struct CreateAcronymContext: Encodable {
  let title = "Create An Acronym"
  let users: Future<[User]>
}

struct EditAcronymContext: Encodable {
  // 1
  let title = "Edit Acronym"
  // 2
  let acronym: Acronym
  // 3
  let users: Future<[User]>
  // 4
  let editing = true
}
