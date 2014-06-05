--CabalVersionFinder.hs

{-
long story short,  i had no versions written down in my .cabal and my sandbox blew up.
Using the build logs to get the versions of my packages and to rebuild my sandbox from
scratch
-}

-- read version file and get package name and version
import Distribution.PackageDescription.Parse as DPP
import Distribution.PackageDescription
import Distribution.Verbosity
import Distribution.Package
import Distribution.Version
import Text.ParserCombinators.ReadP
import Data.Version
import Data.Char
import Prelude as P
import Data.String as DS
import Data.List as DL
import Data.List.Split as DLS
import Control.Monad
import Data.Maybe

readVersion =  fst . P.last . (readP_to_S parseVersion)
hyph = '-'
readPkg s = (P.reverse $ P.drop (P.length ver + 1) rs, readVersion $ ver)
  where
    rs = P.reverse s
    ver = P.reverse $ P.takeWhile (hyph /=) rs

-- withinVersion

readInstalledPkgs
  = (P.map getPkg) . (P.filter (isPrefixOf "package: "))  . DS.lines
    where 
      pkgHead = "package: "
      getPkg = readPkg . (drop (P.length pkgHead))


cabalFileWithVersions cabalFile buildLog newcabalFile = do
  pkgDesc <- readPackageDescription verbose cabalFile 
--  P.putStrLn $ show $ $  pkgdesc
  oldCabal <- P.readFile cabalFile
  bLog <- P.readFile buildLog 
  newDeps <- makeNewCabal pkgDesc bLog
  let cE = (condExecutables pkgDesc)
      headcE = head cE
      finalPkgdesc =  pkgDesc {condExecutables = (fst headcE, (snd headcE) {condTreeConstraints = newDeps} ) : tail cE,
                              packageDescription = (packageDescription pkgDesc) {buildDepends = newDeps}  }
  writePackageDescription newcabalFile $ packageDescription finalPkgdesc    
--  P.writeFile 
  return ()

makeNewCabal genPackDesc bLog
  = return $ matchNames (readInstalledPkgs bLog) $ P.map (\d@(Dependency (PackageName s) v) -> (s, d) ) deps  --readInstalledPkgs bLog
    where
      deps = condTreeConstraints . snd . (!!0 ) . condExecutables $ genPackDesc

runScript = cabalFileWithVersions
              "/home/dan/repos/fuin/src/torrentcamo.cabal"
              "/home/dan/repos/fuin/src/.cabal-sandbox/logs/build.log"
              "newCabal"

--getCabalDeps = (P.map extractPkgName) . (splitOn ",") . (!! 1) . (splitOn "Build-Depends:")
  
extractPkgName = (P.takeWhile (not . isSpace)) . (P.dropWhile isSpace)

matchNames pkgs names =  P.map
  (\(n, (Dependency name vr)) ->  Dependency name $ fromJust $ mplus (fmap withinVersion $ P.lookup n pkgs) (Just vr) ) names

