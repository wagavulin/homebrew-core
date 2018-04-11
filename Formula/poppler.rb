class Poppler < Formula
  desc "PDF rendering library (based on the xpdf-3.0 code base)"
  homepage "https://poppler.freedesktop.org/"
  url "https://poppler.freedesktop.org/poppler-0.63.0.tar.xz"
  sha256 "27cc8addafc791e1a26ce6acc2b490926ea73a4f89196dd8a7742cff7cf8a111"
  revision 1
  head "https://anongit.freedesktop.org/git/poppler/poppler.git"

  bottle do
    sha256 "18c7d69aa30cacef9374448e1aa540ef18ab89ea9bcebd880985e143f2146c9c" => :high_sierra
    sha256 "a209bacaaaf60559ad709c6224a981e2c1d4f3ca4a5ed92928fc1dd8c11b6a7b" => :sierra
    sha256 "ddbd43d9a40bd55a465f2f6c522abe9366b5ae9e4d22012cc9a3abaf101ab197" => :el_capitan
  end

  option "with-qt", "Build Qt5 backend"
  option "with-little-cms2", "Use color management system"
  option "with-nss", "Use NSS library for PDF signature validation"

  deprecated_option "with-qt4" => "with-qt"
  deprecated_option "with-qt5" => "with-qt"
  deprecated_option "with-lcms2" => "with-little-cms2"

  depends_on "cmake" => :build
  depends_on "gobject-introspection" => :build
  depends_on "pkg-config" => :build
  depends_on "cairo"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glib"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "openjpeg"
  depends_on "qt" => :optional
  depends_on "little-cms2" => :optional
  depends_on "nss" => :optional

  conflicts_with "pdftohtml", "pdf2image", "xpdf",
    :because => "poppler, pdftohtml, pdf2image, and xpdf install conflicting executables"

  patch :DATA

  resource "font-data" do
    url "https://poppler.freedesktop.org/poppler-data-0.4.8.tar.gz"
    sha256 "1096a18161f263cccdc6d8a2eb5548c41ff8fcf9a3609243f1b6296abdf72872"
  end

  needs :cxx11 if build.with?("qt") || MacOS.version < :mavericks

  def install
    ENV.cxx11 if build.with?("qt") || MacOS.version < :mavericks

    args = std_cmake_args + %W[
      -DENABLE_XPDF_HEADERS=ON
      -DENABLE_GLIB=ON
      -DBUILD_GTK_TESTS=OFF
      -DWITH_GObjectIntrospection=ON
      -DENABLE_QT4=OFF
      -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
      -DCMAKE_INSTALL_NAME_DIR=#{prefix}/lib
    ]

    if build.with? "qt"
      args << "-DENABLE_QT5=ON"
    else
      args << "-DENABLE_QT5=OFF"
    end

    if build.with? "little-cms2"
      args << "-DENABLE_CMS=lcms2"
    else
      args << "-DENABLE_CMS=none"
    end

    system "cmake", ".", *args
    system "make", "install"
    system "make", "clean"
    system "cmake", ".", "-DBUILD_SHARED_LIBS=OFF", *args
    system "make"
    lib.install "libpoppler.a"
    lib.install "cpp/libpoppler-cpp.a"
    lib.install "glib/libpoppler-glib.a"
    resource("font-data").stage do
      system "make", "install", "prefix=#{prefix}"
    end
  end

  test do
    system "#{bin}/pdfinfo", test_fixtures("test.pdf")
  end
end

__END__
diff --git a/glib/CMakeLists.txt b/glib/CMakeLists.txt
index e089ef8..9584735 100644
--- a/glib/CMakeLists.txt
+++ b/glib/CMakeLists.txt
@@ -115,6 +115,7 @@ if (HAVE_INTROSPECTION)
   include(GObjectIntrospectionMacros)
   set(INTROSPECTION_GIRS)
   set(INTROSPECTION_SCANNER_ARGS "--add-include-path=${CMAKE_CURRENT_SOURCE_DIR} --warn-all")
+  set(INTROSPECTION_SCANNER_ARGS ${INTROSPECTION_SCANNER_ARGS} --library-path=${CMAKE_CURRENT_BINARY_DIR})
   set(INTROSPECTION_COMPILER_ARGS "--includedir=${CMAKE_CURRENT_SOURCE_DIR}")

   set(introspection_files ${poppler_glib_SRCS} ${poppler_glib_public_headers})
