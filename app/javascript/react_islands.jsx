// Entry point for the React "islands": small React components mounted into
// server-rendered pages. Rails renders an empty element with
// data-react-component="Name" and data-props='{...}' (see the react_component
// helper); this finds each one and mounts the matching component.
//
// To add a component: create it in ./components and register it below.
import AuthDialog from './components/AuthDialog';
import FeedMore from './components/FeedMore';
import GardenCards from './components/GardenCards';
import GardenLayout from './components/GardenLayout';
import GardenPicker from './components/GardenPicker';
import GrowingTable from './components/GrowingTable';
import HarvestChart from './components/HarvestChart';
import LocationPicker from './components/LocationPicker';
import NurseryPlanter from './components/NurseryPlanter';
import PhotoDialog from './components/PhotoDialog';
import PhotoPicker from './components/PhotoPicker';
import PlantPicker from './components/PlantPicker';
import PlantingPicker from './components/PlantingPicker';
import PlantingActions from './components/PlantingActions';
import PlantingRating from './components/PlantingRating';
import SeedLibrary from './components/SeedLibrary';
import SeedStack from './components/SeedStack';
import {mountIslands, registerIslands} from './islands';

registerIslands({AuthDialog, FeedMore, GardenCards, GardenLayout, GardenPicker, GrowingTable, HarvestChart, LocationPicker, NurseryPlanter, PhotoDialog, PhotoPicker, PlantPicker, PlantingPicker, PlantingActions, PlantingRating, SeedLibrary, SeedStack});

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => mountIslands());
} else {
  mountIslands();
}
