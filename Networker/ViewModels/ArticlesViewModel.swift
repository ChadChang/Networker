/// Sample code from the book, Expert Swift,
/// published at raywenderlich.com, Copyright (c) 2021 Razeware LLC.
/// See LICENSE for details. Thank you for supporting our work!
/// Visit https://www.raywenderlich.com/books/expert-swift

import SwiftUI
import Combine

class ArticlesViewModel: ObservableObject {
  private var networker: Networking
  @Published private(set) var articles: [Article] = []

  private var cancellables: Set<AnyCancellable> = []

  init(networker: Networking) {
    self.networker = networker
    self.networker.delegate = self
  }

  func fetchArticles() {
    /* 沒用 extension 版本
    let request = ArticleRequest()
    let decoder = JSONDecoder()
    networker.fetch(request)
      .decode(type: Articles.self, decoder: decoder)
      .map { $0.data.map { $0.article } }
      .replaceError(with: [])
      .receive(on: DispatchQueue.main)
      .assign(to: \.articles, on: self)
      .store(in: &cancellables)
     */
    let request = ArticleRequest()
    networker.fetch(request)
      .tryMap([Article].init)
      .replaceError(with: [])
//      .receive(on: DispatchQueue.main) // ArticlesViewModel 實作了 transformPublisher always 放到 mainqueue
      .assign(to: \.articles, on: self)
      .store(in: &cancellables)
  }

  func fetchImage(for article: Article) {
    guard article.downloadedImage == nil,
          let articleIndex = articles.firstIndex(where: { $0.id == article.id }) else {
      return
    }

    let request = ImageRequest(url: article.image)
    networker.fetch(request)
      .map(UIImage.init)
      .replaceError(with: nil)
//      .receive(on: DispatchQueue.main) // ArticlesViewModel 實作了 transformPublisher always 放到 mainqueue
      .sink { [weak self] image in
        self?.articles[articleIndex].downloadedImage = image
      }
      .store(in: &cancellables)
  }
}

extension ArticlesViewModel: NetworkingDelegate {
  func headers(for networking: Networking) -> [String: String] {
    return ["Content-Type": "application/vnd.api+json;charset=utf-8"]
  }

  func networking(
    _ networking: Networking,
    transformPublisher publisher: AnyPublisher<Data, URLError>
  ) -> AnyPublisher<Data, URLError> {
    publisher.receive(on:
                        DispatchQueue.main).eraseToAnyPublisher()
  }
}
