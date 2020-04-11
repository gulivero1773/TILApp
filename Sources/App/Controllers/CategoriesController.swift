import Vapor

struct CategoriesController: RouteCollection {
  func boot(router: Router) throws {
    let categoriesRoute = router.grouped("api", "categories")
    categoriesRoute.get(use: getAllHandler)
    categoriesRoute.get(Category.parameter, use: getHandler)
    categoriesRoute.get(Category.parameter, "acronyms", use: getAcronymsHandler)

      /*
       Создайте ПО TokenAuthenticationMiddleware для пользователя. При этом используется BearerAuthenticationMiddleware для извлечения токена носителя из запроса. Затем промежуточное программное обеспечение преобразует этот токен вошедшего в систему пользователя.
       */
      let tokenAuthMiddleware = User.tokenAuthMiddleware()
      let guardAuthMiddleware = User.guardAuthMiddleware()
      /*
       Создайте группу маршрутов, используя tokenAuthMiddleware и guardAuthMiddleware, чтобы защитить маршрут для создания аббревиатуры с аутентификацией токена.
       */
      let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    
    
    tokenAuthGroup.post(Category.self, use: createHandler)
  }

  func createHandler(_ req: Request, category: Category) throws -> Future<Category> {
    return category.save(on: req)
  }

  func getAllHandler(_ req: Request) throws -> Future<[Category]> {
    return Category.query(on: req).all()
  }

  func getHandler(_ req: Request) throws -> Future<Category> {
    return try req.parameters.next(Category.self)
  }

  func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
    return try req.parameters.next(Category.self).flatMap(to: [Acronym].self) { category in
      try category.acronyms.query(on: req).all()
    }
  }
}
