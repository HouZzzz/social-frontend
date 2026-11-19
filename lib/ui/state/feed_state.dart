/// состояния экрана ленты
enum FeedState {
  initial,
  loading,
  loaded,
  error;

  bool get isLoading => this == FeedState.loading;
  bool get isError => this == FeedState.error;
  bool get hasData => this == FeedState.loaded;
}
